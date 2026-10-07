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
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: python3 tools/nextcloud_login_live_acceptance.py "
            "<private-test-account.json> <private-app-credentials.json> <report.json>"
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
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            executable_path=os.getenv("BUSYMARK_CHROME_PATH", "/usr/bin/google-chrome"),
            headless=True,
            # Disposable acceptance only: trust the explicitly supplied leaf key.
            args=(["--ignore-certificate-errors-spki-list=" + os.environ["BUSYMARK_TEST_TLS_SPKI"]]
                  if "BUSYMARK_TEST_TLS_SPKI" in os.environ else []),
        )
        try:
            page = browser.new_page()
            page.goto(flow["login"], wait_until="networkidle", timeout=60000)
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
        finally:
            browser.close()
    report = {
        "ok": True,
        "externalBrowserOpened": external_browser,
        "pending404": True,
        "browserGrant": True,
        "success200Once": True,
    }
    Path(sys.argv[3]).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("Live browser Login Flow v2 acceptance passed.")


if __name__ == "__main__":
    main()
