#!/usr/bin/env python3
"""Normalize observable fixture semantics from an official Writerside web ZIP.

Usage: extract_writerside_semantics.py ARTIFACT.zip SNAPSHOT.json [--check]
The snapshot excludes generated IDs, dates, CSS and navigation chrome.
"""
import json
import pathlib
import sys
import zipfile
from html.parser import HTMLParser


class Topic(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
        self.captures = []
        self.topic_id = None
        self.result = dict(paragraphs=[], quotes=[], shortcuts=[], tooltips=[], tables=[], seealso=[])
        self.table = None
        self.row = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'body':
            self.topic_id = attrs.get('data-id')
            props = json.loads(attrs.get('data-article-props', '{}'))
            self.result['seealso'] = [dict(title=category['title'], links=[
                dict(title=link['text'], topic=pathlib.PurePosixPath(link['url']).stem)
                for link in category.get('links', [])]) for category in props.get('seeAlso', [])]
        in_article = 'article' in self.stack
        parent = self.stack[-1] if self.stack else None
        if in_article:
            if tag == 'table':
                self.table = []
                self.result['tables'].append(self.table)
            if tag == 'tr' and self.table is not None:
                self.row = []
                self.table.append(self.row)
            kind = ('paragraphs' if tag == 'p' and parent == 'article' else
                    'quotes' if tag == 'blockquote' else
                    'shortcuts' if tag == 'kbd' else
                    'tooltips' if 'tooltip' in attrs.get('class', '').split() else
                    'cell' if tag in ('td', 'th') else None)
            if kind:
                self.captures.append([len(self.stack), tag, kind, attrs, []])
        if tag not in {'meta', 'link', 'img', 'br', 'hr', 'input', 'source', 'wbr'}:
            self.stack.append(tag)

    def handle_data(self, text):
        for capture in self.captures:
            capture[4].append(text)

    def handle_endtag(self, tag):
        if tag not in self.stack:
            return
        depth = len(self.stack) - 1 - self.stack[::-1].index(tag)
        completed = [capture for capture in self.captures if capture[0] >= depth]
        self.captures = [capture for capture in self.captures if capture[0] < depth]
        for _, _, kind, attrs, chunks in completed:
            text = ' '.join(''.join(chunks).split())
            if kind == 'cell':
                self.row.append(dict(text=text, header=tag == 'th',
                    colspan=int(attrs.get('colspan', 1)), rowspan=int(attrs.get('rowspan', 1))))
            elif kind == 'tooltips':
                self.result[kind].append(dict(text=text, summary=attrs.get('title', '')))
            else:
                self.result[kind].append(text)
        self.stack = self.stack[:depth]


def extract(archive):
    result = {}
    with zipfile.ZipFile(archive) as bundle:
        for name in sorted(bundle.namelist()):
            if name.endswith('.html') and name != 'index.html':
                topic = Topic()
                topic.feed(bundle.read(name).decode('utf-8'))
                if topic.topic_id:
                    result[topic.topic_id] = topic.result
    return {'builderVersion': '2026.08.0328', 'topics': result}


if __name__ == '__main__':
    result = extract(sys.argv[1])
    snapshot = pathlib.Path(sys.argv[2])
    if '--check' in sys.argv:
        assert result == json.loads(snapshot.read_text()), 'Official semantic output differs from the checked-in snapshot'
    else:
        snapshot.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
