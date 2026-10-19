#!/usr/bin/env python3
"""Apply BusyMark's liveness patch to verified copies, never the pub cache."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess


def prepare(source: Path, output: Path, *, build_root: Path) -> None:
    # The caller selects the build boundary independently of the output. Allow
    # an explicitly external/symlinked build root, but no redirects below it.
    selected_root = Path(os.path.abspath(build_root))
    requested = Path(os.path.abspath(output))
    try:
        relative = requested.relative_to(selected_root)
    except ValueError as error:
        raise RuntimeError(f"Generated source must be below build root {selected_root}") from error
    if not relative.parts:
        raise RuntimeError("Generated source must not replace the build root")
    output = selected_root.resolve(strict=True)
    for component in relative.parts:
        output = output / component
        if output.is_symlink():
            raise RuntimeError(f"Refusing a redirected generated source: {output}")
        if output.exists() and not output.is_dir():
            raise RuntimeError(f"Refusing a non-directory generated parent: {output}")
    source = source.resolve()
    if output == source or source in output.parents:
        raise RuntimeError("Patched output must be outside the dependency source")
    here = Path(__file__).resolve().parent
    lock = json.loads((here / "source.lock.json").read_text())
    patch = here / "retired-window.patch"
    if hashlib.sha256(patch.read_bytes()).hexdigest() != lock["patchSha256"]:
        raise RuntimeError("Yaru liveness patch does not match source.lock.json")
    for name, expected in lock["upstream"].items():
        if hashlib.sha256((source / name).read_bytes()).hexdigest() != expected:
            raise RuntimeError(
                f"Unexpected Yaru source: {source / name}. "
                "Resolve pubspec.lock's yaru_window_linux 0.2.2; review this patch "
                "before changing the pinned source. No unpatched fallback is allowed."
            )
    # Validate the entire write plan before copying anything. Generated notices
    # and the retained patch are writable outputs too. Never follow a symlink
    # or truncate a hard-linked file outside this generated tree.
    names = [*lock["upstream"], patch.name, "BUSYMARK-CHANGES.md"]
    for name in names:
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise RuntimeError(f"Invalid generated source path: {name}")
        target = output / relative
        parents = target.parents[:len(relative.parts) - 1]
        for path in [*parents, target]:
            if path.is_symlink():
                raise RuntimeError(f"Refusing a redirected generated source: {path}")
        for path in parents:
            if path.exists() and not path.is_dir():
                raise RuntimeError(f"Refusing a non-directory generated parent: {path}")
        if target.exists():
            info = target.stat()
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                raise RuntimeError(f"Refusing a redirected generated source: {target}")
    output.mkdir(parents=True, exist_ok=True)
    for name in lock["upstream"]:
        target = output / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source / name, target)
    subprocess.run(
        ["patch", "--batch", "--fuzz=0", "-p1", "-i", str(patch)],
        cwd=output, check=True,
    )
    shutil.copyfile(patch, output / patch.name)
    shutil.copyfile(here / "README.md", output / "BUSYMARK-CHANGES.md")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--build-root", type=Path, required=True,
                        help="Explicit CMake/fixture build root; redirects below it are rejected")
    args = parser.parse_args()
    prepare(args.source, args.output, build_root=args.build_root)
