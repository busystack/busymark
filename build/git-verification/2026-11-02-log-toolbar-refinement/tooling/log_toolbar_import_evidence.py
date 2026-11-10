from pathlib import Path, PurePosixPath
import hashlib
import json
import tarfile

source = Path('/home/albert/busystack/.native-git-verification/log-toolbar-refinement/log-toolbar-refinement-evidence.tar.gz')
target = Path('/home/albert/busystack/busymark/build/git-verification/2026-11-02-log-toolbar-refinement')
expected = 'f1397d1577c22e8f2a4913ea3fe193d470363bec6042cf2f60f01c64705b345c'
assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
with tarfile.open(source) as archive:
    for member in archive.getmembers():
        name = PurePosixPath(member.name)
        assert not name.is_absolute() and '..' not in name.parts
        assert member.isfile() and name.parts[0] in (
            'runtime', 'native-runtime', 'tooling', 'captures', 'investigation-captures')
        data = archive.extractfile(member).read()
        path = target / str(name)
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.suffix in ('.log', '.txt'):
            raw = data.decode('utf-8')
            assert raw.encode('utf-8') == data
            path = path.with_suffix(path.suffix+'.json')
            path.write_text(json.dumps(dict(sha256=hashlib.sha256(data).hexdigest(),
                                            encoding='utf-8', transcript=raw), indent=2)+'\n')
        else:
            path.write_bytes(data)
(target/'evidence-archive.json').write_text(json.dumps(dict(
    path=str(source), sha256=expected, bytes=source.stat().st_size,
    transcripts='Original bytes are in the archive. log.json/txt.json retain exact UTF-8 text with original SHA256.'),indent=2)+'\n')
metadata = json.loads((target/'runtime/native-captures.json').read_text())
for name, sha in metadata['captures'].items():
    assert hashlib.sha256((target/'captures'/name).read_bytes()).hexdigest() == sha
print(json.dumps(dict(captures=len(metadata['captures']), archiveSha256=expected)))
