#!/usr/bin/env python3
"""Assert supported authored-reference behavior in the pinned builder output."""
import sys
import zipfile
from html.parser import HTMLParser

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.destinations = []
        self.ids = set()
        self.text = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'a':
            self.destinations.append(attrs.get('href'))

    def handle_data(self, text):
        self.text.append(text)

with zipfile.ZipFile(sys.argv[1]) as bundle:
    source, target = Links(), Links()
    source.feed(bundle.read('source.html').decode('utf-8'))
    target.feed(bundle.read('target.html').decode('utf-8'))
    assert source.destinations.count('target.html#actual-id') == 3
    assert '#explicit-heading' in source.destinations
    assert 'source.html#explicit-heading' in target.destinations
    assert 'explicit-heading' in source.ids and 'actual-id' in target.ids
    assert not any('missing' in (destination or '') for destination in source.destinations)
    assert 'Authored reusable content.' in ''.join(source.text)
print('Official authored links, reference definitions, explicit IDs, include and code exclusions passed')
