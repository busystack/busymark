#!/usr/bin/env python3
"""Verify relocated release-smoke exports in current installed browser engines.

Requires Selenium 4.48+, Firefox/geckodriver, and Chrome/chromedriver. The browser
uses a dead outbound proxy and BiDi observation; only the local HTTP server is
allowed. No script is added to the exported files.
"""
import argparse
import base64
import functools
import http.server
import json
import shutil
import subprocess
import tempfile
import threading
from pathlib import Path
from urllib.parse import urlparse
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.print_page_options import PrintOptions
from selenium.webdriver.firefox.service import Service as FirefoxService


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('export_root', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--firefox', default='/snap/firefox/current/usr/lib/firefox/firefox')
    parser.add_argument('--geckodriver', default='/snap/firefox/current/usr/lib/firefox/geckodriver')
    parser.add_argument('--chrome', default='/usr/bin/google-chrome')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    relocated = Path(tempfile.mkdtemp(prefix='busymark-relocated-html-'))
    for name in ['offline.html', 'offline.assets', 'writerside']:
        source = args.export_root / name
        if source.is_dir(): shutil.copytree(source, relocated / name)
        else: shutil.copy2(source, relocated / name)
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=relocated)
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    report = {'relocated_root': str(relocated), 'checks': []}
    try:
        for engine in ['chromium', 'firefox']:
            if engine == 'chromium':
                options = webdriver.ChromeOptions()
                options.binary_location = args.chrome
                for flag in ['--headless=new', '--disable-background-networking', '--no-first-run',
                             '--proxy-server=http://127.0.0.1:9', '--proxy-bypass-list=127.0.0.1;localhost']:
                    options.add_argument(flag)
                options.enable_bidi = True
                browser = webdriver.Chrome(options=options)
            else:
                options = webdriver.FirefoxOptions()
                options.binary_location = args.firefox
                options.add_argument('-headless')
                options.enable_bidi = True
                for key, value in {'network.proxy.type': 1, 'network.proxy.http': '127.0.0.1',
                                   'network.proxy.http_port': 9, 'network.proxy.ssl': '127.0.0.1',
                                   'network.proxy.ssl_port': 9, 'network.proxy.no_proxies_on': '127.0.0.1,localhost',
                                   'network.captive-portal-service.enabled': False,
                                   'network.connectivity-service.enabled': False}.items():
                    options.set_preference(key, value)
                browser = webdriver.Firefox(options=options, service=FirefoxService(executable_path=args.geckodriver))
            print(engine, 'launched', flush=True)
            browser.set_page_load_timeout(20)
            browser.set_window_size(1280, 950)
            requests, blocked = [], []
            def observe(event):
                data = event if isinstance(event, dict) else vars(event)
                request = data.get('request') or {}
                url = request.get('url', '') if isinstance(request, dict) else request.url
                requests.append(url)
                parsed = urlparse(url)
                if parsed.scheme in ('http', 'https') and parsed.hostname not in ('127.0.0.1', 'localhost'):
                    blocked.append(url)
            browser.network.add_event_handler('before_request', observe)
            try:
                for mode in ['file', 'http']:
                    for relative in ['offline.html', 'writerside/index.html', 'writerside/Welcome.html', 'writerside/reference.html', 'writerside/hidden.html']:
                        url = (relocated / relative).as_uri() if mode == 'file' else f'http://127.0.0.1:{server.server_port}/{relative}'
                        requests.clear(); blocked.clear()
                        browser.get(url)
                        values = browser.execute_script('''return {title:document.title,
                          scripts:document.scripts.length,
                          images:[...document.images].map(i=>({src:i.getAttribute('src'),ok:i.complete&&i.naturalWidth>0})),
                          css:[...document.styleSheets].reduce((n,s)=>n+s.cssRules.length,0),
                          font:getComputedStyle(document.documentElement).fontSize,
                          width:document.documentElement.scrollWidth,viewport:innerWidth,
                          anchors:[...document.querySelectorAll('a[href^="#"]')].every(a=>!!document.getElementById(decodeURIComponent(a.hash.slice(1))))};''')
                        assert values['scripts'] == 0, values
                        assert values['css'] > 20 and values['font'] == '17px', values
                        assert all(image['ok'] for image in values['images']), values
                        assert values['anchors'] and values['width'] <= values['viewport'], values
                        assert not blocked, blocked
                        browser.find_element(By.TAG_NAME, 'body').send_keys(Keys.TAB)
                        assert browser.execute_script('return document.activeElement.tagName') == 'A'
                        details = browser.find_elements(By.CSS_SELECTOR, 'article details > summary')
                        if details:
                            summary = details[0]
                            summary.click()
                            before = browser.execute_script('return arguments[0].parentElement.open', summary)
                            summary.send_keys(Keys.SPACE)
                            assert browser.execute_script('return arguments[0].parentElement.open', summary) != before
                            browser.execute_script('arguments[0].parentElement.open=false', summary)
                        if relative == 'offline.html':
                            assert browser.find_elements(By.CSS_SELECTOR, 'sup a[href="#fn-one"]')
                            assert browser.find_elements(By.CSS_SELECTOR, '.footnotes #fn-one a[href="#fnref-one"]')
                            assert 'Footnote[^one]' not in browser.find_element(By.TAG_NAME, 'article').text
                            browser.find_element(By.CSS_SELECTOR, 'article a[href="#tables"]').click()
                            assert browser.execute_script('return decodeURIComponent(location.hash)') == '#tables'
                            browser.execute_script('scrollTo(0,0)')
                        if relative.startswith('writerside/'):
                            assert browser.find_elements(By.CSS_SELECTOR, '.instance-nav a[aria-current="page"]') or relative.endswith('hidden.html')
                        stem = f'{engine}-{mode}-{relative.replace("/", "-")}'
                        browser.save_screenshot(str(args.output / f'{stem}.png'))
                        options = PrintOptions(); options.background = True
                        pdf = args.output / f'{stem}.pdf'
                        pdf.write_bytes(base64.b64decode(browser.print_page(options)))
                        printed = subprocess.check_output(['pdftotext', '-layout', str(pdf), '-'], text=True)
                        if relative == 'offline.html': assert 'Disclosure body must print.' in printed, printed
                        if relative.endswith('reference.html'): assert 'All details are printable.' in printed, printed
                        if relative.endswith(('index.html','Welcome.html')):
                            assert 'All Linux instructions.' in printed and 'All Windows instructions.' in printed
                        # WebDriver may evaluate code, but source-injected scripts
                        # must still be blocked by the document CSP.
                        browser.execute_script("const s=document.createElement('script');s.textContent='window.__htmlProbe=1';document.body.append(s)")
                        assert browser.execute_script('return window.__htmlProbe || 0') == 0
                        assert not blocked, blocked
                        report['checks'].append({'engine':engine,'version':browser.capabilities['browserVersion'],
                                                 'mode':mode,'page':relative,'images':len(values['images']),
                                                 'requests':list(requests),'print_bytes':pdf.stat().st_size})
                        print(engine, mode, relative, 'PASS', flush=True)
            finally:
                browser.quit()
        report['ok'] = True
    finally:
        server.shutdown()
        (args.output / 'browser-report.json').write_text(json.dumps(report, indent=2))
    print(json.dumps({'ok':True,'checks':len(report['checks']),'relocated_root':str(relocated)}))

if __name__ == '__main__': main()
