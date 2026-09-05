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
    names = ['offline.html', 'offline.assets', 'writerside']
    customized = (args.export_root / 'automatic-single.html').exists()
    if customized: names += ['automatic-single.html', 'dark-assets.html', 'dark-assets.assets', 'writerside-embedded']
    for name in names:
        source = args.export_root / name
        if source.is_dir(): shutil.copytree(source, relocated / name)
        else: shutil.copy2(source, relocated / name)
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=relocated)
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    report = {'relocated_root': str(relocated), 'checks': []}
    try:
        profiles = [('chromium', None), ('firefox', 'light')]
        if customized: profiles.append(('firefox', 'dark'))
        for engine, firefox_scheme in profiles:
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
                options.set_preference('layout.css.prefers-color-scheme.content-override', 0 if firefox_scheme == 'dark' else 1)
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
                requests.append(url if not url.startswith('data:') else url.split(',')[0] + ',…')
                parsed = urlparse(url)
                if parsed.scheme in ('http', 'https') and parsed.hostname not in ('127.0.0.1', 'localhost'):
                    blocked.append(url)
            browser.network.add_event_handler('before_request', observe)
            try:
                for mode in ['file', 'http']:
                    pages = ['offline.html', 'writerside/index.html', 'writerside/Welcome.html', 'writerside/reference.html', 'writerside/hidden.html']
                    if customized: pages += ['automatic-single.html', 'dark-assets.html', 'writerside-embedded/index.html', 'writerside-embedded/Welcome.html', 'writerside-embedded/reference.html', 'writerside-embedded/hidden.html']
                    if firefox_scheme == 'dark': pages = ['automatic-single.html']
                    for relative in pages:
                        custom = relative in ('automatic-single.html', 'dark-assets.html') or relative.startswith('writerside-embedded/')
                        embedded = relative == 'automatic-single.html' or relative.startswith('writerside-embedded/')
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
                        assert values['css'] > 20 and values['font'] == ('20px' if custom else '17px'), values
                        assert all(image['ok'] for image in values['images']), values
                        assert values['anchors'] and values['width'] <= values['viewport'], values
                        assert not blocked, blocked
                        if embedded:
                            assert all(image['src'].startswith('data:image/') for image in values['images']), values
                        if custom:
                            assert browser.find_elements(By.CSS_SELECTOR, '.heading-number')
                            assert 'serif' in browser.execute_script('return getComputedStyle(document.documentElement).fontFamily')
                            if relative in ('automatic-single.html', 'dark-assets.html'):
                                assert browser.execute_script("return getComputedStyle(document.querySelector('article')).getPropertyValue('--custom-css-proof').trim()") == 'applied'
                            if relative == 'automatic-single.html':
                                preferences = ['dark', 'light'] if engine == 'chromium' else [firefox_scheme]
                                for preference in preferences:
                                    if engine == 'chromium':
                                        browser.execute_cdp_cmd('Emulation.setEmulatedMedia', {'features': [{'name': 'prefers-color-scheme', 'value': preference}]})
                                    background = 'rgb(21, 25, 31)' if preference == 'dark' else 'rgb(255, 255, 255)'
                                    assert browser.execute_script('return getComputedStyle(document.documentElement).backgroundColor') == background
                                    browser.save_screenshot(str(args.output / f'{engine}-{mode}-automatic-{preference}.png'))
                                if engine == 'chromium': browser.execute_cdp_cmd('Emulation.setEmulatedMedia', {'features': []})
                            else:
                                assert browser.execute_script('return getComputedStyle(document.documentElement).backgroundColor') == 'rgb(21, 25, 31)'
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
                        if relative in ('offline.html', 'automatic-single.html', 'dark-assets.html'):
                            assert browser.find_elements(By.CSS_SELECTOR, 'sup a[href="#fn-one"]')
                            assert browser.find_elements(By.CSS_SELECTOR, '.footnotes #fn-one a[href="#fnref-one"]')
                            assert 'Footnote[^one]' not in browser.find_element(By.TAG_NAME, 'article').text
                            browser.find_element(By.CSS_SELECTOR, 'article a[href="#tables"]').click()
                            assert browser.execute_script('return decodeURIComponent(location.hash)') == '#tables'
                            browser.execute_script('scrollTo(0,0)')
                        if relative.startswith(('writerside/', 'writerside-embedded/')):
                            assert browser.find_elements(By.CSS_SELECTOR, '.instance-nav a[aria-current="page"]') or relative.endswith('hidden.html')
                        stem = f'{engine}{"-dark" if firefox_scheme == "dark" else ""}-{mode}-{relative.replace("/", "-")}'
                        browser.save_screenshot(str(args.output / f'{stem}.png'))
                        options = PrintOptions(); options.background = True
                        pdf = args.output / f'{stem}.pdf'
                        pdf.write_bytes(base64.b64decode(browser.print_page(options)))
                        printed = subprocess.check_output(['pdftotext', '-layout', str(pdf), '-'], text=True)
                        if relative in ('offline.html', 'automatic-single.html', 'dark-assets.html'): assert 'Disclosure body must print.' in printed, printed
                        if relative.endswith('reference.html'): assert 'All details are printable.' in printed, printed
                        if relative.endswith(('index.html','Welcome.html')):
                            assert 'All Linux instructions.' in printed and 'All Windows instructions.' in printed
                        # WebDriver may evaluate code, but source-injected scripts
                        # must still be blocked by the document CSP.
                        browser.execute_script("const s=document.createElement('script');s.textContent='window.__htmlProbe=1';document.body.append(s)")
                        assert browser.execute_script('return window.__htmlProbe || 0') == 0
                        assert not blocked, blocked
                        report['checks'].append({'engine':engine,'version':browser.capabilities['browserVersion'],
                                                 'mode':mode,'page':relative,'browser_color_scheme':firefox_scheme,'images':len(values['images']),
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
