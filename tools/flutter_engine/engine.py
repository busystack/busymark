#!/usr/bin/env python3
"""Pinned, private Linux engine builds; never changes an installed Flutter SDK."""

import argparse
import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent.parent
LOCK = json.loads((HERE / "engine.lock.json").read_text())


def fail(message):
    raise RuntimeError(message)


def digest(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def elf_identity(path):
    """Code and loader dependencies survive Snapcraft's RUNPATH adjustment."""
    with Path(path).open("rb") as f:
        header = f.read(64)
        if header[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", header, 18)[0] != 62:
            fail(f"Not a Linux x64 engine ELF: {path}")
        offset = struct.unpack_from("<Q", header, 40)[0]
        size, count, strings_index = struct.unpack_from("<HHH", header, 58)
        f.seek(offset)
        sections = [struct.unpack("<IIQQQQIIQQ", f.read(size)) for _ in range(count)]
        names = sections[strings_index]
        f.seek(names[4])
        strings = f.read(names[5])
        text = [s for s in sections if strings[s[0]:].split(b"\0", 1)[0] == b".text"]
        if len(text) != 1:
            fail("Engine ELF has no unique code section")
        f.seek(text[0][4])
        code = hashlib.sha256(f.read(text[0][5])).hexdigest()
    import re
    notes = subprocess.check_output(["readelf", "-n", str(path)], text=True)
    dynamic = subprocess.check_output(["readelf", "-d", str(path)], text=True)
    ids = re.findall(r"Build ID: (\w+)", notes)
    if len(ids) != 1:
        fail("Engine ELF must have one build ID")
    return {"textSHA256": code, "buildId": ids[0], "needed": sorted(re.findall(r"\(NEEDED\).*\[(.*?)\]", dynamic))}


def key():
    for patch in LOCK["patches"]:
        if digest(HERE / patch["file"]) != patch["sha256"]:
            fail(f"Reviewed patch changed: {patch['file']}; review and update engine.lock.json")
    return hashlib.sha256((HERE / "engine.lock.json").read_bytes()).hexdigest()


def cache_root():
    return Path(os.environ.get("BUSYMARK_ENGINE_CACHE", PROJECT / ".build/flutter-engine")).expanduser().resolve() / key()


def run(args, cwd=None, **kwargs):
    print("+ " + " ".join(str(x) for x in args), flush=True)
    return subprocess.run([str(x) for x in args], cwd=cwd, check=True, **kwargs)


def git_head(path):
    return subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()


def framework(root, require_dart=True):
    sdk = root / "sdk"
    if not (sdk / "bin/flutter").is_file():
        fail("Private framework missing. Run: python3 tools/flutter_engine/engine.py prepare")
    if git_head(sdk) != LOCK["frameworkRevision"]:
        fail(f"Framework revision mismatch: {sdk}")
    tag = subprocess.run(["git", "-C", str(sdk), "rev-parse", "--verify", "refs/tags/" + LOCK["frameworkVersion"] + "^{commit}"], text=True, capture_output=True)
    if tag.returncode or tag.stdout.strip() != LOCK["frameworkRevision"]:
        fail("Pinned framework version tag missing or mismatched. Run: python3 tools/flutter_engine/engine.py prepare --framework-only")
    if (sdk / "bin/internal/engine.version").read_text().strip() != LOCK["engineRevision"]:
        fail("Framework/engine pin mismatch")
    if require_dart:
        dart = sdk / "bin/cache/dart-sdk"
        for name, wanted in [("version", LOCK["dartVersion"]), ("revision", LOCK["dartRevision"])]:
            if not (dart / name).is_file() or (dart / name).read_text().strip() != wanted:
                fail("Private framework Dart SDK missing or mismatched. Run: python3 tools/flutter_engine/engine.py prepare --framework-only")
    return sdk


def copy_new(source, dest):
    if dest.exists():
        fail(f"Refusing to overwrite {dest}")
    # cp copies data (or reflinks), never hardlinks to another checkout.
    run(["cp", "-a", "--reflink=auto", source, dest])


def clone(url, revision, dest):
    if not dest.exists():
        run(["git", "init", dest])
        run(["git", "remote", "add", "origin", url], cwd=dest)
        run(["git", "fetch", "--depth=1", "origin", revision], cwd=dest)
        run(["git", "checkout", "--detach", "FETCH_HEAD"], cwd=dest)
    if git_head(dest) != revision:
        fail(f"Wrong source revision in {dest}")


def expected_sources(source):
    """Apply the reviewed composition to pristine pin files, without editing source."""
    paths = set()
    for patch in LOCK["patches"]:
        for line in (HERE / patch["file"]).read_text().splitlines():
            if line.startswith("+++ b/"):
                paths.add(line[6:])
    with tempfile.TemporaryDirectory(prefix="busymark-engine-source-") as temp:
        temp = Path(temp)
        for name in paths:
            p = temp / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(subprocess.check_output(["git", "show", LOCK["engineRevision"] + ":" + name], cwd=source))
        for patch in LOCK["patches"]:
            run(["git", "apply", HERE / patch["file"]], cwd=temp)
        return {name: digest(temp / name) for name in sorted(paths)}


def verify_source(source):
    if git_head(source) != LOCK["engineRevision"]:
        fail("Engine source is not the locked revision")
    expected = expected_sources(source)
    changed = set(subprocess.check_output(["git", "diff", "--name-only", "HEAD"], cwd=source, text=True).splitlines())
    if changed != set(expected) or any(digest(source / p) != h for p, h in expected.items()):
        fail("Engine source differs from the reviewed C6 composition; do not reuse this build")
    return expected


@contextlib.contextmanager
def exclusive(root, name=".lock", shared=False):
    root.mkdir(parents=True, exist_ok=True)
    with (root / name).open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_SH if shared else fcntl.LOCK_EX)
        yield


def prepare(args, root):
    sdk = root / "sdk"
    if args.framework_seed and not sdk.exists():
        copy_new(Path(args.framework_seed).resolve(), sdk)
    clone("https://github.com/flutter/flutter.git", LOCK["frameworkRevision"], sdk)
    tag = "refs/tags/" + LOCK["frameworkVersion"]
    if subprocess.run(["git", "rev-parse", "--verify", tag], cwd=sdk, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        run(["git", "fetch", "--depth=1", "origin", tag + ":" + tag], cwd=sdk)
    framework(root, require_dart=False)
    env = os.environ.copy()
    env.update(CI="true", FLUTTER_SUPPRESS_ANALYTICS="true", DEPOT_TOOLS_UPDATE="0")
    run([sdk / "bin/flutter", "--no-version-check", "precache", "--linux"], env=env)
    framework(root)
    if args.framework_only:
        return
    depot = root / "depot_tools"
    clone("https://chromium.googlesource.com/chromium/tools/depot_tools.git", LOCK["depotToolsRevision"], depot)
    source = root / "source"
    if args.source_seed and not source.exists():
        copy_new(Path(args.source_seed).resolve(), source)
    clone("https://github.com/flutter/flutter.git", LOCK["engineRevision"], source)
    shutil.copyfile(HERE / "gclient.py", source / ".gclient")
    env["PATH"] = str(depot) + os.pathsep + env["PATH"]
    run([depot / "gclient", "sync", "--no-history", "--nohooks", "--shallow", "--jobs=4"], cwd=source, env=env)
    changed = subprocess.check_output(["git", "diff", "--name-only", "HEAD"], cwd=source, text=True).strip()
    if not changed:
        for patch in LOCK["patches"]:
            run(["git", "apply", HERE / patch["file"]], cwd=source)
    verify_source(source)
    src = source / "engine/src"
    run([sys.executable, "flutter/third_party/dart/tools/generate_sdk_version_file.py"], cwd=src, env=env)
    run([sys.executable, "flutter/tools/pub_get_offline.py"], cwd=src, env=env)
    run([sys.executable, "flutter/third_party/dart/tools/generate_package_config.py"], cwd=src, env=env)
    run([sys.executable, "build/linux/sysroot_scripts/install-sysroot.py", "--arch=x64"], cwd=src, env=env)


def build(args, root):
    builder_sha = digest(HERE / "engine.py")
    framework(root)
    source = root / "source"
    sources = verify_source(source)
    src = source / "engine/src"
    if args.jobs < 1:
        fail("--jobs must be positive")
    ninja = shutil.which("ninja")
    if not ninja:
        fail("Install ninja-build before compiling the engine")
    env = os.environ.copy()
    env.update(DEPOT_TOOLS_UPDATE="0", PATH=str(root / "depot_tools") + os.pathsep + env["PATH"])
    clang = src / "flutter/buildtools/linux-x64/clang/bin/clang++"
    version = subprocess.check_output([str(clang), "--version"], text=True)
    if LOCK["clangRevision"] not in version:
        fail("The DEPS-pinned Clang toolchain is missing or mismatched")
    for mode in args.mode:
        name = LOCK["modes"][mode]
        gn = [sys.executable, "flutter/tools/gn", "--runtime-mode=" + mode, *LOCK["gn"]]
        if mode == "debug":
            gn.append("--unoptimized")
        run(gn, cwd=src, env=env)
        built = src / "out" / name
        run([ninja, "-C", "out/" + name, "-j" + str(args.jobs), *LOCK["targets"]], cwd=src, env=env)
        build_portable_native_tests(built, ninja, env, args.jobs)
        fixtures = built / "native-test-fixtures"
        if fixtures.exists():
            shutil.rmtree(fixtures)
        shutil.copytree(built / "gen/flutter/shell/platform/linux/assets", fixtures)
        with exclusive(root, ".artifact-" + mode + ".lock"):
            publish(root, mode, sources, version, builder_sha)


def configure_native_test_fixtures(built):
    """Relocate GN's test-only schema locator; leave engine sources untouched."""
    generated = built / "gen/flutter/shell/platform/linux/_fl__fl_flutter_linux_fixtures.cc"
    source = generated.read_text()
    expected = 'const char* GetFixturesPath() {return "' + str(built / "gen/flutter/shell/platform/linux/assets") + '";} '
    portable = 'const char* GetFixturesPath() {return "native-test-fixtures";} '
    if source.count(expected) != 1:
        fail("Native test fixture locator differs from the pinned GN template; regenerate this mode")
    generated.write_text(source.replace(expected, portable))


def build_portable_native_tests(built, ninja, env, jobs):
    # First complete the normal GN/Ninja build above. GN tracks its generated
    # fixture locator as an input and would overwrite a pre-build adjustment.
    # A second test-only build uses that exact completed graph under another
    # manifest filename, so it recompiles/relinks the locator without invoking
    # GN's build.ninja regeneration edge. No engine source or assertion changes.
    configure_native_test_fixtures(built)
    shutil.copyfile(built / "build.ninja", built / "native-tests.ninja")
    run([ninja, "-C", built, "-f", "native-tests.ninja", "-j" + str(jobs), "flutter_linux_unittests"], env=env)
    if not portable_native_tests(built / "flutter_linux_unittests"):
        fail("GN replaced the native test fixture locator; portable test build failed")


def portable_native_tests(path):
    marker, absolute = b"native-test-fixtures\0", b"/gen/flutter/shell/platform/linux/assets\0"
    found, previous = False, b""
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            data = previous + block
            if absolute in data:
                return False
            found |= marker in data
            previous = data[-max(len(marker), len(absolute)):]
    return found


def publish(root, mode, sources, clang, builder_sha):
    name = LOCK["modes"][mode]
    built = root / "source/engine/src/out" / name
    dest = root / "artifacts/engine/src/out" / name
    partial = dest.with_name(name + ".partial")
    if partial.exists():
        shutil.rmtree(partial)
    partial.mkdir(parents=True)
    required = ["libflutter_linux_gtk.so", "flutter_linux", "icudtl.dat", "dart-sdk", "flutter_patched_sdk", "gen/dart-pkg/sky_engine", "gen/const_finder.dart.snapshot", "font-subset", "flutter_linux_unittests", "native-test-fixtures", "args.gn"]
    if mode != "debug":
        required.append("gen_snapshot")
    for name in required:
        p = built / name
        if not p.exists():
            fail(f"Missing mode-matched build input: {p}; rebuild {mode}")
        out = partial / name
        out.parent.mkdir(parents=True, exist_ok=True)
        if p.is_dir():
            shutil.copytree(p, out)  # Materialize SDK links; relocatable cache.
        else:
            shutil.copy2(p, out)
    symbols = root / "symbols" / mode
    symbols.mkdir(parents=True, exist_ok=True)
    lib = partial / "libflutter_linux_gtk.so"
    run(["objcopy", "--only-keep-debug", lib, symbols / "libflutter_linux_gtk.so.debug"])
    run(["strip", "--strip-unneeded", lib])
    run(["objcopy", "--add-gnu-debuglink=" + str(symbols / "libflutter_linux_gtk.so.debug"), lib])
    import shlex
    src = root / "source/engine/src"
    gtk = shlex.split(subprocess.check_output(["pkg-config", "--cflags", "--libs", "gtk+-3.0"], text=True))
    run([src / "flutter/buildtools/linux-x64/clang/bin/clang++", "-std=c++17", "-O1", "-g", "-pthread", "-DFLUTTER_LINUX_COMPILATION", '-DBM2_RENDERER_SOURCE="' + str(src / "flutter/shell/platform/linux/fl_view_renderer.cc") + '"', HERE / "tests/renderer-retirement-test.cc", src / "flutter/shell/platform/linux/fl_compositor.cc", "-I" + str(src), *gtk, "-o", partial / "renderer-retirement"])
    files = {str(p.relative_to(partial)): digest(p) for p in sorted(partial.rglob("*")) if p.is_file()}
    receipt = {"schema": 2, "key": key(), "mode": mode, "architecture": LOCK["architecture"], "frameworkRevision": LOCK["frameworkRevision"], "engineRevision": LOCK["engineRevision"], "sources": sources, "clang": clang, "builderSHA256": builder_sha, "componentSourceSHA256": digest(HERE / "tests/renderer-retirement-test.cc"), "symbolsSHA256": digest(symbols / "libflutter_linux_gtk.so.debug"), "elf": elf_identity(lib), "files": files}
    (partial / "busymark-engine.json").write_text(json.dumps(receipt, indent=2) + "\n")
    if dest.exists():
        shutil.rmtree(dest)
    partial.rename(dest)
    verify(root, mode)


def verify(root, mode):
    out = root / "artifacts/engine/src/out" / LOCK["modes"][mode]
    p = out / "busymark-engine.json"
    if not p.is_file():
        fail(f"Corrected {mode} engine missing. Run: python3 tools/flutter_engine/engine.py build --mode {mode}")
    receipt = json.loads(p.read_text())
    if (receipt.get("key"), receipt.get("mode"), receipt.get("architecture")) != (key(), mode, LOCK["architecture"]):
        fail("Engine cache revision/mode/architecture mismatch; rebuild the selected mode")
    if receipt.get("frameworkRevision") != LOCK["frameworkRevision"] or receipt.get("engineRevision") != LOCK["engineRevision"]:
        fail("Artifact framework/engine revisions differ from the lock")
    if not isinstance(receipt.get("clang"), str) or LOCK["clangRevision"] not in receipt["clang"]:
        fail("Artifact compiler differs from the DEPS-pinned Clang; rebuild/import the locked toolchain artifacts")
    expected = json.loads((HERE / "reviewed-sources.json").read_text())
    if receipt.get("sources") != expected:
        fail("Artifact was not built from the reviewed C6 sources")
    if receipt.get("componentSourceSHA256") != digest(HERE / "tests/renderer-retirement-test.cc"):
        fail("Cached lifetime regressions differ from the maintained source; rebuild")
    for name in ["libflutter_linux_gtk.so", "icudtl.dat", "flutter_linux/flutter_linux.h", "dart-sdk/version", "dart-sdk/revision", "dart-sdk/bin/dart", "dart-sdk/bin/dartaotruntime", "dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot", "flutter_patched_sdk/platform_strong.dill", "gen/dart-pkg/sky_engine/pubspec.yaml", "gen/const_finder.dart.snapshot", "font-subset", "flutter_linux_unittests", "native-test-fixtures/ubuntu-20.04/gschemas.compiled", "renderer-retirement", "args.gn"]:
        if name not in receipt["files"]:
            fail(f"Incomplete artifact receipt: {name}")
    if mode != "debug" and "gen_snapshot" not in receipt["files"]:
        fail("AOT mode is missing its matching snapshot compiler")
    for name, want in receipt["files"].items():
        part = Path(name)
        if part.is_absolute() or ".." in part.parts:
            fail("Unsafe artifact manifest path")
        f = out / name
        if not f.is_file() or digest(f) != want:
            fail(f"Engine artifact missing or mismatched: {f}; rebuild/import a verified {mode} cache")
    if (out / "dart-sdk/version").read_text().strip() != LOCK["dartVersion"]:
        fail("Engine Dart SDK does not match the pinned framework")
    if (out / "dart-sdk/revision").read_text().strip() != LOCK["dartRevision"]:
        fail("Engine Dart revision does not match the pinned snapshots")
    import re
    gn = (out / "args.gn").read_text()
    for name, want in {"flutter_runtime_mode": '"' + mode + '"', "target_cpu": '"x64"', "target_os": '"linux"', "engine_version": '"' + LOCK["engineRevision"] + '"', "enable_lto": "false", "is_debug": "true" if mode == "debug" else "false"}.items():
        values = re.findall(r"^" + name + r"\s*=\s*(.*?)\s*$", gn, re.M)
        if not values or values[-1] != want:
            fail(f"Cached GN configuration mismatches {name}; rebuild {mode}")
    if elf_identity(out / "libflutter_linux_gtk.so") != receipt.get("elf"):
        fail("Engine ELF identity differs from its source-build receipt")
    if not portable_native_tests(out / "flutter_linux_unittests"):
        fail("Native test fixture locator is not portable; rebuild/import the complete mode archive")
    symbols = root / "symbols" / mode / "libflutter_linux_gtk.so.debug"
    if receipt.get("schema") != 2 or not symbols.is_file() or digest(symbols) != receipt.get("symbolsSHA256"):
        fail(f"Matching {mode} engine symbols missing or mismatched; rebuild/import the complete mode archive")
    notes = subprocess.check_output(["readelf", "-n", str(symbols)], text=True)
    if "Build ID: " + receipt["elf"]["buildId"] not in notes:
        fail("Engine symbol build ID differs from the runtime library")
    return out, receipt


def check_bundle(root, mode, bundle, packaged=False):
    out, receipt = verify(root, mode)
    pairs = [("lib/libflutter_linux_gtk.so", "libflutter_linux_gtk.so"), ("data/icudtl.dat", "icudtl.dat")]
    for target, source in pairs:
        p = bundle / target
        if packaged and source == "libflutter_linux_gtk.so":
            if elf_identity(p) != receipt["elf"]:
                fail("Packaged engine code/build ID/dependencies differ from the verified C6 input")
            continue
        if not p.is_file() or digest(p) != receipt["files"][source]:
            fail(f"Built bundle selected wrong {source}: {p}")
    record = dict(receipt)
    record["packagedEngineSHA256"] = digest(bundle / "lib/libflutter_linux_gtk.so")
    (bundle / "data/busymark-engine.json").write_text(json.dumps(record, indent=2) + "\n")


def check_cmake(args):
    values = {}
    for item in args.environment:
        k, sep, v = item.partition("=")
        if sep:
            values[k] = v
    mode = args.mode.lower()
    name = LOCK["modes"].get(mode)
    if not name or values.get("LOCAL_ENGINE") != name or values.get("LOCAL_ENGINE_HOST") != name:
        fail("BusyMark requires its corrected Linux engine. Use: python3 tools/flutter.py build linux --" + mode)
    src = Path(values.get("FLUTTER_ENGINE", "")).resolve()
    if src.parts[-3:] != ("artifacts", "engine", "src"):
        fail("Engine was not selected from a verified BusyMark artifact cache")
    root = src.parents[2]
    verify(root, mode)
    sdk = Path(args.framework).resolve()
    if git_head(sdk) != LOCK["frameworkRevision"] or (sdk / "bin/internal/engine.version").read_text().strip() != LOCK["engineRevision"]:
        fail("CMake framework is not the locked Flutter/engine pair")
    if args.ephemeral:
        out, receipt = verify(root, mode)
        for name in ["libflutter_linux_gtk.so", "icudtl.dat"] + [n for n in receipt["files"] if n.startswith("flutter_linux/")]:
            p = args.ephemeral / name
            if not p.is_file() or digest(p) != receipt["files"][name]:
                fail(f"Flutter assembled a mismatched engine input: {p}")
    if args.bundle:
        check_bundle(root, mode, args.bundle)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("key")
    p = commands.add_parser("prepare")
    p.add_argument("--source-seed", help="Copy a pinned private checkout as a dependency/build cache; it is never modified")
    p.add_argument("--framework-seed", help="Copy the pinned framework SDK; never use or edit a shared SDK")
    p.add_argument("--framework-only", action="store_true", help="Prepare SDK only when verified engine artifacts are imported from cache")
    p = commands.add_parser("build")
    p.add_argument("--mode", nargs="+", choices=LOCK["modes"], default=list(LOCK["modes"]))
    p.add_argument("--jobs", type=int, default=4)
    for command in ["verify", "test", "export"]:
        p = commands.add_parser(command)
        p.add_argument("--mode", choices=LOCK["modes"], required=True)
        if command == "export":
            p.add_argument("--output", type=Path, required=True)
    p = commands.add_parser("import")
    p.add_argument("archive", type=Path)
    p = commands.add_parser("check-cmake")
    p.add_argument("--mode", required=True)
    p.add_argument("--framework", required=True)
    p.add_argument("--ephemeral", type=Path)
    p.add_argument("--bundle", type=Path)
    p.add_argument("environment", nargs="*")
    p = commands.add_parser("check-bundle")
    p.add_argument("--mode", choices=LOCK["modes"], required=True)
    p.add_argument("--bundle", type=Path, required=True)
    p.add_argument("--packaged", action="store_true")
    args = parser.parse_args()
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "amd64"):
        fail("The reviewed engine supports Linux x64 only; other architectures require their own validated build")
    if args.command == "key":
        print(key())
        return
    if args.command == "check-cmake":
        check_cmake(args)
        return
    root = cache_root()
    readonly = args.command in ("verify", "test", "export", "check-bundle")
    with exclusive(root, ".artifact-" + args.mode + ".lock" if readonly else ".lock", shared=readonly):
        if args.command == "prepare":
            prepare(args, root)
        elif args.command == "build":
            build(args, root)
        elif args.command == "verify":
            out, receipt = verify(root, args.mode)
            print(json.dumps({"path": str(out), "key": key(), "engineSHA256": receipt["files"]["libflutter_linux_gtk.so"]}))
        elif args.command == "test":
            out, _ = verify(root, args.mode)
            with tempfile.TemporaryDirectory(prefix="busymark-engine-test-") as temp:
                env = os.environ.copy()
                env["HOME"] = temp
                for name in ["CONFIG", "CACHE", "DATA", "STATE"]:
                    path = Path(temp) / name.lower()
                    path.mkdir()
                    env["XDG_" + name + "_HOME"] = str(path)
                env["GSETTINGS_BACKEND"] = "memory"
                run([out / "flutter_linux_unittests"], cwd=out, env=env)
                for case in ["active-presentation", "pending-redraw", "first-frame", "partial"]:
                    run([out / "renderer-retirement", case], env=env)
        elif args.command == "check-bundle":
            check_bundle(root, args.mode, args.bundle, args.packaged)
        elif args.command == "export":
            out, _ = verify(root, args.mode)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            with tarfile.open(args.output, "x:xz", preset=3) as archive:
                archive.add(out, arcname="artifacts/engine/src/out/" + out.name)
                archive.add(root / "symbols" / args.mode, arcname="symbols/" + args.mode)
        elif args.command == "import":
            with tempfile.TemporaryDirectory(prefix="import-", dir=root) as temp:
                with tarfile.open(args.archive) as archive:
                    for member in archive.getmembers():
                        part = Path(member.name)
                        if part.is_absolute() or ".." in part.parts or member.issym() or member.islnk() or not (member.isfile() or member.isdir()):
                            fail("Unsafe engine archive member")
                    archive.extractall(temp, filter="data")
                found = list(Path(temp).glob("artifacts/engine/src/out/*/busymark-engine.json"))
                if len(found) != 1:
                    fail("Engine archive must contain exactly one complete mode")
                mode = json.loads(found[0].read_text())["mode"]
                _, incoming = verify(Path(temp), mode)
                dest = root / "artifacts/engine/src/out" / LOCK["modes"][mode]
                dest.parent.mkdir(parents=True, exist_ok=True)
                if dest.exists():
                    _, existing = verify(root, mode)
                    if existing != incoming:
                        fail(f"Different artifact already exists: {dest}; use a clean/new cache directory")
                    print(f"Already imported and verified: {dest}")
                    return
                symbols = root / "symbols" / mode
                if symbols.exists():
                    fail(f"Symbols already exist: {symbols}; use a new cache directory")
                symbols.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(Path(temp) / "symbols" / mode), symbols)
                shutil.move(str(found[0].parent), dest)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError, KeyError, ValueError) as error:
        print("BusyMark engine: " + str(error), file=sys.stderr)
        sys.exit(1)
