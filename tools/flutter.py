#!/usr/bin/env python3
"""Project Flutter entry point: pinned framework; corrected Linux GTK engine."""

import os
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / "flutter_engine"))
import engine


def main():
    args = sys.argv[1:]
    if not args:
        raise RuntimeError("Usage: python3 tools/flutter.py <Flutter command> [arguments]")
    if args[0] == "attach":
        raise RuntimeError("Unmanaged attach cannot verify the loaded GTK engine. Start with python3 tools/flutter.py run -d linux (add --profile for profiling), use its hot reload/restart commands and VM-service/DevTools URL")
    if any(a.startswith("--local-engine") for a in args):
        raise RuntimeError("Engine selection is controlled by engine.lock.json; remove manual local-engine flags")
    if any(a == "--use-application-binary" or a.startswith("--use-application-binary=") for a in args):
        raise RuntimeError("A prebuilt application bypasses corrected-engine assembly checks. Build/run with this wrapper, or verify a bundle with tools/flutter_engine/engine.py check-bundle before launching it directly")
    root = engine.cache_root()
    sdk = engine.framework(root)
    native = args[0] == "run" or args[:2] == ["build", "linux"]
    flags = []
    if native:
        modes = [m for m in engine.LOCK["modes"] if "--" + m in args]
        if len(modes) > 1:
            raise RuntimeError("Select exactly one build mode")
        mode = modes[0] if modes else ("release" if args[0] == "build" else "debug")
        engine.verify(root, mode)
        name = engine.LOCK["modes"][mode]
        flags = ["--local-engine-src-path=" + str(root / "artifacts/engine/src"), "--local-engine=" + name, "--local-engine-host=" + name]
        if args[0] == "run" and not any(x in args for x in ("-d", "--device-id")) and not any(x.startswith("--device-id=") for x in args):
            args += ["-d", "linux"]
    env = os.environ.copy()
    env.update(FLUTTER_ROOT=str(sdk), FLUTTER_SUPPRESS_ANALYTICS="true")
    status = subprocess.call([str(sdk / "bin/flutter"), *flags, *args], cwd=engine.PROJECT, env=env)
    if status:
        return status
    if args[:2] == ["build", "linux"]:
        engine.check_bundle(root, mode, engine.PROJECT / "build/linux/x64" / mode / "bundle")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, KeyError, ValueError) as error:
        print("BusyMark Flutter: " + str(error), file=sys.stderr)
        sys.exit(1)
