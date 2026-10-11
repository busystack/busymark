"""Optional browser acceptance for an isolated Nextcloud test account.

Requires requests and Playwright with a locally installed Chrome binary.
Writes the one-time app-password result only to the requested private file.
Never use a production account as an automated acceptance fixture.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

import requests
from playwright.sync_api import sync_playwright


def main():
    if len(sys.argv) not in (4, 5):
        raise SystemExit(
            "Usage: python3 tools/nextcloud_login_live_acceptance.py "
            "<private-test-account.json> <private-app-credentials.json> <report.json> [private-BusyMark-portable-link.json]"
        )
    account = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    server = account["server"].rstrip("/")
    start = requests.post(
        server + "/index.php/login/v2",
        headers={"User-Agent": "BusyMark live acceptance"},
        timeout=30,
        allow_redirects=False,
    )
    assert start.status_code == 200, "Login Flow start failed."
    flow = start.json()
    poll = flow["poll"]
    pending = requests.post(
        poll["endpoint"],
        data={"token": poll["token"]},
        timeout=30,
        allow_redirects=False,
    )
    assert pending.status_code == 404, "Login Flow pending response differs."
    try:
        launched = subprocess.run(
            ["xdg-open", flow["login"]],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=10,
            check=False,
        )
        external_browser = launched.returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        external_browser = False
    portable_checks = None
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            executable_path=os.getenv("BUSYMARK_CHROME_PATH", "/usr/bin/google-chrome"),
            headless=True,
            # Disposable acceptance only: trust the explicitly supplied leaf key.
            args=(["--ignore-certificate-errors-spki-list=" + os.environ["BUSYMARK_TEST_TLS_SPKI"]]
                  if "BUSYMARK_TEST_TLS_SPKI" in os.environ else []),
        )
        try:
            context = browser.new_context()
            page = context.new_page()
            page.goto(flow["login"], wait_until="domcontentloaded", timeout=60000)
            if page.locator("#user").count() == 0:
                page.get_by_role("button", name=re.compile("Log in", re.I)).first.click()
            page.locator("#user").fill(account["user"])
            page.locator("#password").fill(account["password"])
            page.locator("button[type=submit]").click()
            page.get_by_role("button", name=re.compile("Grant access", re.I)).click()
            page.wait_for_timeout(500)
            success = requests.post(
                poll["endpoint"],
                data={"token": poll["token"]},
                timeout=30,
                allow_redirects=False,
            )
            assert success.status_code == 200, "Browser authorization failed."
            result = success.json()
            assert result["loginName"] and result["appPassword"] and result["server"]
            descriptor = os.open(
                sys.argv[2],
                os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW,
                0o600,
            )
            os.fchmod(descriptor, 0o600)
            with os.fdopen(descriptor, "w", encoding="utf-8") as output:
                json.dump(result, output)
            after = requests.post(
                poll["endpoint"],
                data={"token": poll["token"]},
                timeout=30,
                allow_redirects=False,
            )
            assert after.status_code == 404, "Login Flow success was not one-time."
            if len(sys.argv) == 5:
                published = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
                source_url = published["href"].rsplit("/note/", 1)[0] + "/note/" + str(published["sourceId"])
                page.goto(source_url, wait_until="domcontentloaded", timeout=60000)
                wizard = page.locator('#firstrunwizard[role=dialog]')
                if wizard.count() and wizard.is_visible():
                    wizard.get_by_role('button', name=re.compile('close', re.I)).first.click()
                    wizard.wait_for(state='hidden')
                link = page.locator('a[href="' + published["href"] + '"]').filter(has_text="Selected link").first
                if link.count() == 0:
                    preview = page.get_by_role("button", name=re.compile("preview|read.?mode", re.I))
                    if preview.count():
                        preview.first.click()
                link.wait_for(state="visible", timeout=60000)
                page.screenshot(path=str(Path(sys.argv[3]).with_suffix(".source.png")), full_page=True)
                # Nextcloud's rich editor opens ordinary links through its
                # link context menu; keyboard modifiers select editor content.
                link.click(button='right')
                page.wait_for_timeout(300)
                page.screenshot(path=str(Path(sys.argv[3]).with_suffix('.link-menu.png')), full_page=True)
                Path(sys.argv[3]).with_suffix('.link-menu.html').write_text(page.content())
                with page.expect_popup(timeout=60000) as popup:
                    page.get_by_role('button', name='Open link', exact=True).click()
                popup.value.wait_for_load_state('domcontentloaded', timeout=60000)
                page.wait_for_timeout(1500)
                page.screenshot(path=str(Path(sys.argv[3]).with_suffix('.after-click.png')), full_page=True)
                Path(sys.argv[3]).with_suffix('.after-click.html').write_text(page.content())
                opened = next((candidate for candidate in page.context.pages if re.search(r"/note/" + str(published["targetId"]) + r"(?:[#?]|$)", candidate.url)), None)
                Path(sys.argv[3]).with_suffix('.pages.json').write_text(json.dumps([p.url for p in page.context.pages]))
                if opened is None:
                    probes = []
                    for route in ['/index.php/apps/notes/note/', '/apps/notes/note/']:
                        probe = page.context.new_page()
                        probe.goto(server + route + str(published['targetId']), wait_until='domcontentloaded', timeout=60000)
                        probe.wait_for_timeout(1500)
                        probes.append({'requested': server + route + str(published['targetId']), 'url': probe.url,
                            'headings': probe.locator('.ProseMirror h1').all_text_contents()})
                    Path(sys.argv[3]).with_suffix('.route-probes.json').write_text(json.dumps(probes,indent=2))
                assert opened is not None, "Stored BusyMark link did not open the intended browser note."
                opened.get_by_text(published["marker"], exact=True).first.wait_for(state="visible", timeout=60000)
                opened.screenshot(path=str(Path(sys.argv[3]).with_suffix(".target.png")), full_page=True)
                browser_url = opened.url
                route_checks = {}
                for name, route in [("frontController", "/index.php/apps/notes/note/"), ("pretty", "/apps/notes/note/")]:
                    probe = page.context.new_page()
                    requested = server + route + str(published["targetId"])
                    probe.goto(requested, wait_until="domcontentloaded", timeout=60000)
                    probe.wait_for_timeout(1500)
                    route_checks[name] = {
                        "requested": requested,
                        "opened": probe.url,
                        "openedIntendedNote": bool(re.search(r"/note/" + str(published["targetId"]) + r"(?:[#?]|$)", probe.url)) and probe.get_by_text(published["marker"], exact=True).count() > 0,
                    }
                    probe.close()
                opened.goto(published["href"] + "#heading", wait_until="domcontentloaded", timeout=60000)
                opened.get_by_text(published["marker"], exact=True).first.wait_for(state="visible", timeout=60000)
                portable_checks = {
                    "storedBusyMarkLinkOpenedIntendedNote": True,
                    "generatedHref": published["href"],
                    "browserNoteUrl": browser_url,
                    "routes": route_checks,
                    "browserFragment": opened.evaluate("location.hash"),
                    "browserHasBusyMarkHeadingId": opened.locator('[id="heading"]').count() > 0,
                    "browserHeadingIds": opened.locator('.ProseMirror h1, .ProseMirror h2, .ProseMirror h3').evaluate_all('(nodes) => nodes.map(node => node.id)'),
                    "installationPath": requests.utils.urlparse(server).path,
                }
        finally:
            browser.close()
    report = {
        "ok": True,
        "externalBrowserOpened": external_browser,
        "pending404": True,
        "browserGrant": True,
        "success200Once": True,
        **({"portableNotes": portable_checks} if portable_checks is not None else {}),
    }
    Path(sys.argv[3]).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("Live browser Login Flow v2 acceptance passed.")


if __name__ == "__main__":
    main()
