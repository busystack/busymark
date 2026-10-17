#!/usr/bin/env python3
"""Build the live, animated complete-core retirement control with selected inputs."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.parse import unquote, urlparse

import engine


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=engine.LOCK["modes"], required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = engine.cache_root()
    engine.framework(root)
    selected, _ = engine.verify(root, args.mode)
    output = args.output.resolve()
    if output.exists():
        engine.fail("Control output must be a new directory; preserve prior results")
    packages = engine.PROJECT / ".dart_tool/package_config.json"
    entries = json.loads(packages.read_text())["packages"]
    manager = next(p for p in entries if p["name"] == "window_manager")
    uri = urlparse(manager["rootUri"])
    manager_root = Path(unquote(uri.path)) if uri.scheme == "file" else (packages.parent / unquote(uri.path)).resolve()
    plugin = engine.PROJECT / "build/linux/x64" / args.mode / "bundle/lib/libwindow_manager_plugin.so"
    if not plugin.is_file():
        engine.fail("Build the same-mode BusyMark bundle first to supply its locked native plugin")
    bundle = output / "bundle"
    (bundle / "lib").mkdir(parents=True)
    assets = bundle / "data/flutter_assets"
    assets.mkdir(parents=True)
    source = engine.HERE / "tests/control"
    kernel = output / "app.dill"
    commands = []

    def run(command):
        commands.append([str(s) for s in command])
        # frontend_server is a persistent protocol server. EOF requests normal
        # completion after its first compilation rather than waiting for input.
        engine.run(command, stdin=subprocess.DEVNULL)

    command = [selected / "dart-sdk/bin/dartaotruntime", selected / "dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot", "--sdk-root", str(selected / "flutter_patched_sdk") + "/", "--target=flutter", "--packages", packages, "--output-dill", kernel]
    if args.mode != "debug":
        command += ["--aot", "--tfa", "--target-os", "linux"]
    command += ["-Ddart.vm.product=" + str(args.mode == "release").lower(), "-Ddart.vm.profile=" + str(args.mode == "profile").lower(), source / "main.dart"]
    run(command)
    if args.mode == "debug":
        shutil.copy2(kernel, assets / "kernel_blob.bin")
    else:
        run([selected / "gen_snapshot", "--snapshot_kind=app-aot-elf", "--elf=" + str(bundle / "lib/libapp.so"), "--strip", kernel])
    import shlex
    gtk = shlex.split(subprocess.check_output(["pkg-config", "--cflags", "--libs", "gtk+-3.0", "libhandy-1"], text=True))
    run(["clang++", "-std=c++17", "-O2", "-g", source / "main.cc", "-I" + str(selected), "-I" + str(manager_root / "linux/include"), "-L" + str(selected), "-L" + str(plugin.parent), "-lwindow_manager_plugin", "-lflutter_linux_gtk", "-Wl,-rpath,$ORIGIN/lib", *gtk, "-o", bundle / "busymark"])
    for src, dest in [(plugin, bundle / "lib" / plugin.name), (selected / "libflutter_linux_gtk.so", bundle / "lib/libflutter_linux_gtk.so"), (selected / "icudtl.dat", bundle / "data/icudtl.dat")]:
        shutil.copy2(src, dest)
    engine.check_bundle(root, args.mode, bundle)
    (output / "control-build.json").write_text(json.dumps({"key": engine.key(), "mode": args.mode, "commands": commands, "sourceHashes": {p.name: engine.digest(p) for p in source.iterdir() if p.is_file()}, "pluginSHA256": engine.digest(plugin), "outputHashes": {str(p.relative_to(bundle)): engine.digest(p) for p in bundle.rglob("*") if p.is_file()}}, indent=2) + "\n")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, KeyError, ValueError, StopIteration, subprocess.CalledProcessError) as error:
        print("BusyMark engine control: " + str(error), file=sys.stderr)
        sys.exit(1)
