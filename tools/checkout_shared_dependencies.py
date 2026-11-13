#!/usr/bin/env python3
"""Materialize hash-pinned sibling packages without modifying existing trees."""
import json
from pathlib import Path
import sys
from shared_source_archives import materialize

root = Path(__file__).resolve().parents[1]
if sys.argv[1:] not in ([], ['--check']):
    raise SystemExit('usage: checkout_shared_dependencies.py [--check]')
manifest = json.loads((root / 'tool/shared_dependencies.json').read_text())
if manifest.get('schema') != 1 or manifest.get('layout') != 'sibling-working-trees':
    raise SystemExit('Unsupported shared dependency manifest')
for dependency in manifest['dependencies']:
    destination = (root / dependency['path']).resolve()
    if destination.parent != root.parent or destination.name != dependency['name']:
        raise SystemExit('Unsafe sibling source destination')
    materialize(root, dependency, destination, sys.argv[1:] == ['--check'])
