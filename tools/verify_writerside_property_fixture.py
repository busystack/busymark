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
        self.descendants = {}
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for _, parent in self.stack:
            if 'id' in parent: self.descendants.setdefault(parent['id'], []).append((tag, attrs))
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


def verify_literal_references(actual):
    link = actual.elements['code-reference'][0]
    assert link['href'].endswith(('properties.html', 'authoring.html')), link
    assert actual.texts['code-reference'] == '{id="linked-literal"}'
    assert any(tag == 'code' or 'code' in attrs.get('class', '').split()
               for tag, attrs in actual.descendants['code-reference'])
    image = actual.elements['alt-reference'][0]
    assert image['alt'] == '{id="image-literal"}', image
    assert image['src'].endswith('/logo.png') and image['width'] == '24', image
    assert 'linked-literal' not in actual.elements and 'image-literal' not in actual.elements


def verify_numbered_item(actual, identity, outer_start, nested_start):
    _, parents = actual.elements[identity]
    lists = [attrs for tag, attrs in parents if tag == 'ol']
    assert lists[-1]['start'] == str(outer_start), (identity, lists)
    nested = [attrs for tag, attrs in actual.descendants[identity] if tag == 'ol']
    assert len(nested) == 1 and nested[0]['start'] == str(nested_start), (identity, nested)


if len(sys.argv) > 2 and sys.argv[2] == 'native-defaults':
    with zipfile.ZipFile(sys.argv[1]) as archive:
        actual = Elements(archive.read('properties.html').decode('utf-8'))
        layout = actual.elements['layout-default'][0]
        assert layout['data-style'] == 'title-left', layout
        assert layout['data-title-width'] == 'medium', layout
    print('Native reset layout HTML: module Medium verified')
    sys.exit(0)

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
        corrections = Elements(archive.read('inspector-corrections.html').decode('utf-8'))
        assert 'literal-code' not in corrections.elements
        assert any('{id="literal-code"}' in text and 'Try' in text for text in corrections.texts.values())
        item, parents = corrections.elements['saved-item']
        assert item['class'] == 'list__item' and any(tag == 'ul' for tag, _ in parents)
        assert corrections.elements['saved-note'][0]['data-type'] == 'note'
        task, parents = corrections.elements['saved-task']
        assert 'checked' not in task and any(a.get('class') == 'list _checkbox' for _, a in parents)
        assert any(a.get('checked') == 'true' for a, _ in corrections.elements.values())
        verify_literal_references(corrections)
        verify_numbered_item(corrections, 'saved-numbered-item', 10, 4)
        verify_numbered_item(corrections, 'saved-marker-item', 3, 4)
    print('Native saved HTML: source inclusion, snippet emphasis, inherited state, literal inline references, ordered starts, list-item and admonition IDs verified')
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
    layout = xml.elements['layout-default'][0]
    assert layout['data-style'] == ('title-left' if defaults else 'title-top'), layout
    if defaults:
        assert layout['data-title-width'] == 'medium', layout
    assert xml.elements['layout-wide'][0]['data-title-width'] == 'wide'
    assert xml.elements['layout-full'][0]['data-style'] == 'title-top'
    assert '{id="literal-code"}' in md.texts['paragraph-code-owner']
    assert '{id="literal-escaped"}' in md.texts['paragraph-escaped-owner']
    assert 'literal-code' not in md.elements and 'literal-escaped' not in md.elements
    for identity, owner in [('owned-link', 'paragraph-link-owner'), ('owned-image', 'paragraph-image-owner')]:
        assert any(attrs.get('id') == owner for _, attrs in md.elements[identity][1]), (identity, owner)
    assert md.elements['native-list'][0]['class'] == 'list _bullet'
    item, parents = md.elements['converted-list-item']
    assert item['class'] == 'list__item' and any(tag == 'ul' for tag, _ in parents)
    assert md.elements['checked-native-list'][0]['class'] == 'list _checkbox'
    assert md.elements['checked-xml-item'][0]['checked'] == 'true'
    assert 'checked' not in md.elements['unchecked-xml-item'][0]
    verify_literal_references(md)
    verify_numbered_item(md, 'numbered-parent', 10, 4)
    verify_numbered_item(md, 'marker-parent', 3, 4)
    verify_numbered_item(md, 'nested-parent', 10, 7)
    for identity, start, nested_start in [('native-numbered-list', 10, 4),
                                         ('native-marker-list', 3, 4),
                                         ('native-override-list', 10, 7)]:
        assert md.elements[identity][0]['start'] == str(start), identity
        nested = [attrs for tag, attrs in md.descendants[identity] if tag == 'ol']
        assert len(nested) == 1 and nested[0]['start'] == str(nested_start), (identity, nested)
    note = md.elements['native-note'][0]
    assert note['class'] == 'prompt' and note['data-type'] == 'note', note
print('Pinned property HTML: collapse, state, inheritance, module layout, literal inline ownership, ordered starts, list/item and admonition IDs, snippet emphasis, formatted titles and images verified')
