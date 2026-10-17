#!/usr/bin/env python3
"""Apply BusyMark's liveness patch to verified copies, never the pub cache."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


def prepare(source: Path, output: Path) -> None:
    source, output = source.resolve(), output.resolve()
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
    output.mkdir(parents=True, exist_ok=True)
    for name in lock["upstream"]:
        target = output / name
        if target.is_symlink() or output not in target.resolve().parents:
            raise RuntimeError(f"Refusing a redirected generated source: {target}")
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
    args = parser.parse_args()
    prepare(args.source.resolve(), args.output.resolve())
