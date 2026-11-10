from pathlib import Path
import hashlib
import json
import subprocess

root = Path('/home/ubuntu/busystack-native-git-verification-20261031')
target = root/'inputs/busymark/build/linux/x64/debug/bundle/busymark'
matches = []
for process in Path('/proc').iterdir():
    if not process.name.isdigit():
        continue
    try:
        if (process/'cmdline').read_bytes().split(b'\0')[0] != str(target).encode():
            continue
        libraries = {row.split(None, 5)[5] for row in (process/'maps').read_text().splitlines()
                     if row.endswith('/libflutter_linux_gtk.so')}
        assert len(libraries) == 1
        library = libraries.pop()
        matches.append(dict(pid=int(process.name), executable=str(target), engine=library,
            engineSha256=hashlib.sha256(Path(library).read_bytes()).hexdigest()))
    except (PermissionError, FileNotFoundError):
        continue
assert len(matches) == 1, matches
assert matches[0]['engineSha256'] == '7a5698608a3c79ad3f123a74bce8074339ffa1a83c896d73ae853c9f92a43cc3'
record = dict(source=subprocess.check_output(['git', 'rev-parse', 'HEAD'],
    cwd=root/'inputs/busymark', text=True).strip(),
    launch='flutter run -d linux --debug --no-pub --dart-entrypoint-args=<fixture>',
    target='lib/main.dart (ordinary application entry point)', processes=matches,
    backend='X11/Xvfb, Openbox, 1440x1000, 96 dpi, DPR 1.0, en_US.UTF-8, text scale 1.0')
(root/'commit-correction-20261101/debug-runtime-receipt.json').write_text(json.dumps(record, indent=2))
print(json.dumps(record))
