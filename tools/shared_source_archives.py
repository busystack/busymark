"""Hash-pinned sibling source archives, without invented upstream locations."""
import hashlib
from pathlib import Path
import tarfile

EXCLUDED = {'.git', '.dart_tool', 'build', 'coverage', '__pycache__', '.idea', '.codex', '.agents'}

def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob('*')):
        relative = path.relative_to(root)
        if any(part in EXCLUDED for part in relative.parts) or path.suffix in {'.pyc', '.log', '.snap'}:
            continue
        if path.is_symlink():
            raise ValueError(f'Symlink in pinned source: {relative}')
        if path.is_file():
            digest.update(relative.as_posix().encode() + b'\0')
            digest.update(b'x' if path.stat().st_mode & 0o111 else b'-')
            digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()

def materialize(root, dependency, destination, check_only=False):
    name = dependency['name']
    source = root / dependency['archive']
    if source.resolve().parent != (root / 'tool/source-dependencies').resolve():
        raise ValueError('Unsafe source archive path')
    if hashlib.sha256(source.read_bytes()).hexdigest() != dependency['sha256']:
        raise ValueError(f'{name} source archive checksum mismatch')
    if destination.exists():
        if tree_digest(destination) != dependency['tree_sha256']:
            raise ValueError(f'Existing {name} differs from its pinned source; preserve local changes and refresh the source archive explicitly')
        return
    if check_only:
        raise ValueError(f'Missing {name}; materialize the bundled source dependencies first')
    destination.mkdir()
    try:
        with tarfile.open(source, 'r:gz') as archive:
            seen = set()
            for entry in archive.getmembers():
                parts = Path(entry.name).parts
                if not entry.isfile() or len(parts) < 2 or parts[0] != name or '..' in parts or entry.name in seen:
                    raise ValueError('Unsafe source archive entry')
                seen.add(entry.name)
                target = destination.joinpath(*parts[1:])
                target.parent.mkdir(parents=True, exist_ok=True)
                with target.open('xb') as output:
                    output.write(archive.extractfile(entry).read())
                target.chmod(0o755 if entry.mode & 0o111 else 0o644)
        if tree_digest(destination) != dependency['tree_sha256']:
            raise ValueError(f'{name} extracted source identity mismatch')
    except Exception:
        # This directory was created by this invocation, never a user's tree.
        import shutil
        shutil.rmtree(destination)
        raise
