"""Assert published behavior of the pinned property fixtures, not just exit status."""
import sys
import zipfile
from html.parser import HTMLParser


class Elements(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.stack = []
        self.elements = {}
        self.texts = {}
        self.images = {}
        self.links = {}
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for _, parent in self.stack:
            if 'id' in parent and tag == 'img': self.images.setdefault(parent['id'], []).append(attrs)
            if 'id' in parent and tag == 'a': self.links.setdefault(parent['id'], []).append(attrs)
        if 'id' in attrs:
            self.elements[attrs['id']] = (attrs, list(self.stack))
        if tag not in {'meta', 'link', 'img', 'br', 'hr', 'input'}:
            self.stack.append((tag, attrs))

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index][0] == tag:
                del self.stack[index:]
                break

    def handle_data(self, data):
        for _, attrs in self.stack:
            if 'id' in attrs:
                self.texts[attrs['id']] = self.texts.get(attrs['id'], '') + data


if len(sys.argv) > 2 and sys.argv[2] == 'native':
    with zipfile.ZipFile(sys.argv[1]) as archive:
        for page in ['inspector.html', 'inspector-markdown.html']:
            actual = Elements(archive.read(page).decode('utf-8'))
            code = actual.elements['saved-code'][0]
            assert code['class'] == 'code-block', (page, code)
            assert code['data-emphasize-lines'] == '1', (page, code)
            snippet = actual.texts['saved-code']
            assert 'second' in snippet and 'third' in snippet and 'first' not in snippet
            if page == 'inspector.html':
                assert any(a.get('data-expandable') == 'true' and
                           a.get('data-expanded') == 'true'
                           for a, _ in actual.elements.values())
    print('Native saved XML/Markdown HTML: source inclusion, extracted snippet, emphasis and inherited definition state verified')
    sys.exit(0)

defaults = len(sys.argv) > 2 and sys.argv[2] == 'defaults'
with zipfile.ZipFile(sys.argv[1]) as archive:
    xml = Elements(archive.read('properties.html').decode())
    md = Elements(archive.read('properties-markdown.html').decode())
    for tag in ['chapter', 'procedure', 'code-block', 'deflist']:
        for case in ['absent', 'false', 'true', 'expanded', 'collapsed',
                     'false-expanded', 'false-collapsed', 'true-expanded', 'true-collapsed']:
            identity = f'{tag}-{case}'
            enabled = case.startswith('true') or defaults and not case.startswith('false')
            expanded = case.endswith('expanded') or defaults and not case.endswith('collapsed')
            attrs, parents = xml.elements[identity]
            if tag in {'chapter', 'procedure'}:
                collapse = [a for _, a in parents if a.get('class') == 'collapse__title']
                assert bool(collapse) == enabled, (identity, parents)
                if enabled:
                    assert (collapse[0].get('data-expanded') == 'true') == expanded, identity
            elif tag == 'code-block':
                assert (attrs['class'] == 'code-collapse') == enabled, (identity, attrs)
                if enabled:
                    assert (attrs['data-is-expanded'] == 'true') == expanded, identity
            else:
                item_suffixes = ['absent', 'inherited', 'collapsed', 'false'] if case.startswith('true-') else ['absent', 'inherited', 'expanded', 'collapsed']
                for item in item_suffixes:
                    item_id = f'{identity}-item-{item}'
                    # The initial fixture contains a spelling preserved in evidence.
                    if item_id not in xml.elements:
                        item_id = f'{identity}-item-item-{item}'
                    item_attrs, _ = xml.elements[item_id]
                    assert (item_attrs['data-expandable'] == 'true') == enabled, item_id
                    if enabled:
                        item_expanded = item == 'expanded' or item == 'inherited' and expanded or item in {'absent', 'false'} and not defaults and expanded
                        assert (item_attrs['data-expanded'] == 'true') == item_expanded, (item_id, item_attrs)
    assert md.elements['md-code'][0]['class'] == 'code-block'
    file_attrs = md.elements['md-file'][0]
    assert (file_attrs['class'] == 'code-collapse') == defaults, file_attrs
    assert file_attrs['data-emphasize-lines'] == '1', file_attrs
    assert 'intro' in md.elements
    snippet = md.texts['md-file']
    assert 'second' in snippet and 'third' in snippet and 'first' not in snippet, snippet
    assert 'Install' in xml.texts['formatted-title'] and 'now' in xml.texts['formatted-title'], xml.texts['formatted-title']
    assert xml.texts['child-title-only'] == 'Child title only'
    assert xml.images['image-xml'][0]['width'] == '48' and xml.images['image-xml'][0]['height'] == '24'
    assert xml.links['image-xml'][0]['class'] == 'lightbox'
    assert xml.images['image-paragraph'][0]['width'] == '16'
    assert md.images['image-markdown'][0]['width'] == '48'
    assert md.links['image-markdown'][0]['class'] == 'lightbox'
    override = md.elements['source-override'][0]
    assert override['src'] == '/other.png' and override['alt'] == 'Different'
    assert override['width'] == '80'
    assert md.elements['reference-override'][0]['href'] == 'properties.html#image-xml'
    assert md.elements['empty-alt'][0]['alt'] == 'Logo'
    assert xml.elements['empty-alt-xml'][0]['alt'] == 'Logo'
    assert md.elements['lang-override'][0]['data-lang'] == 'none'
    variable_chapter, variable_parents = xml.elements['chapter-variable']
    assert any(attrs.get('class') == 'collapse__title' and attrs.get('data-expanded') == 'true'
               for _, attrs in variable_parents)
    assert xml.elements['code-variable'][0]['class'] == 'code-collapse'
    assert xml.elements['code-variable'][0]['data-is-expanded'] == 'true'
    assert md.elements['embedded-code'][0]['class'] == 'code-block'
    assert md.texts['embedded-code'] == 'embedded code'
print('Pinned property HTML: collapse, state, inheritance, defaults, Markdown IDs, snippet emphasis, formatted titles and images verified')
