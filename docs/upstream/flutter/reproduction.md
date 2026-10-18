# Reproduction and upstream patch review

Use a disposable directory, official SDK, isolated HOME/XDG/PUB caches and real
X11 or Wayland session. Never change a shared SDK or an installed application.
The control uses Flutter, GTK/libhandy and `window_manager` 0.5.1 with continuous
frames and the normal prevent-close/set-false/close path. It does not terminate
the process to simulate closure.

```
flutter --version --machine
flutter create --platforms=linux --project-name=close_reproducer control
cd control
flutter pub add window_manager:0.5.1
cp /path/to/busymark2/docs/upstream/flutter/tests/control/main.dart lib/main.dart
cp /path/to/busymark2/docs/upstream/flutter/tests/control/main.cc linux/runner/main.cc
```

In `linux/runner/CMakeLists.txt`, add the following after the runner target has
been created. The generated Flutter plugin CMake already links window_manager.

```cmake
pkg_check_modules(HANDY REQUIRED IMPORTED_TARGET libhandy-1)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::HANDY)
```

```
flutter build linux --release
/usr/bin/python3 /path/to/busymark2/tools/application_close_smoke.py \
  --output /owned/evidence/control-close --cycles 100 --plain \
  --expected-engine build/linux/x64/release/bundle/lib/libflutter_linux_gtk.so -- \
  build/linux/x64/release/bundle/close_reproducer
```

Supply a disposable display and use a short executable alias as the observer
normally does. A library filename/version is not provenance: retain the observer
loaded mapping/device/inode/hash, `/proc/PID/maps`, `readelf -n` build IDs, SDK
archive SHA256 and framework/engine revisions. Compare official releases in
equivalent providers, close timing and fresh/retained profiles. Retain every
fatal/nonzero exit, hang, incomplete observation and cleanup result. A strict
Snap reproduction must use actual confinement and matching GNOME/Mesa content
providers; headless functional results are not real-desktop performance.

For an original-symbol capture, the opt-in
`tools/capture_native_slow_operation.py` launches GDB as process ancestor and
records only owned identities. Debugger timing is diagnostic. Preserve matching
process-root libraries and inspect the exact failing frame/compositor pointers.

## Engine maintainer instructions (review only)

BusyMark no longer builds an engine. To independently review the preserved
experiment upstream, use Flutter's supported engine contributor setup in an
independent source checkout at the exact framework/engine/Dart/depot_tools/clang
revisions in `engine.lock.json`; run dependency synchronization before applying
the five patches in listed order. Do not apply them to another version or a
shared SDK.

The historical source bootstrap used a fresh, independent checkout (never a
copied worktree), with inherited `GIT_*` overrides removed:

```sh
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
git -C depot_tools checkout --detach 251c84c1f36498529399517014e8f7994f762e2e
git init source
git -C source remote add origin https://github.com/flutter/flutter.git
git -C source fetch --depth=1 origin af7e796e161ae0bb1ff0758c71a7105418bd9ded
git -C source checkout --detach FETCH_HEAD
```

Create `source/.gclient` with the exact historical configuration:

```python
solutions = [{
    "name": ".", "url": "https://github.com/flutter/flutter.git",
    "deps_file": "DEPS", "managed": False, "safesync_url": "",
    "custom_deps": {},
    "custom_vars": {"download_android_deps": False,
                    "download_fuchsia_deps": False,
                    "download_jdk": False, "setup_githooks": False},
}]
```

From `source`, with the pinned depot_tools on `PATH` and
`DEPOT_TOOLS_UPDATE=0`, run
`gclient sync --no-history --nohooks --shallow --jobs=4`. Apply the patches from
the source root in `engine.lock.json` order. From `source/engine/src`, run:

```sh
python3 flutter/third_party/dart/tools/generate_sdk_version_file.py
python3 flutter/tools/pub_get_offline.py
python3 flutter/third_party/dart/tools/generate_package_config.py
python3 build/linux/sysroot_scripts/install-sysroot.py --arch=x64
```

The DEPS-provided Clang version must contain
`80743bd43fd5b38fedc503308e7a652e23d3ec93`. Then build:

```
./flutter/tools/gn --runtime-mode=release --no-lto --no-stripped \
  --gn-args='full_dart_sdk=false symbol_level=2'
ninja -C out/host_release flutter_gtk flutter_linux_unittests dart_sdk \
  flutter_patched_sdk generate_snapshot_bins sky_engine const_finder font_subset
(cd out/host_release && ./flutter_linux_unittests \
  --gtest_filter='FlEngineTest.PresentationLastReferenceReturnsToGtk:FlEngineTest.CompletedPresentationReferencesAreBoundedAndDrained:FlEngineTest.CompositorRetirementRunsOnRenderThreadAndRejectsNewFrames:FlEngineTest.FailedRetirementPostJoinsEngineBeforeResourceRelease'
)
```

Use `--runtime-mode=profile`/`out/host_profile` or debug
`--runtime-mode=debug --unoptimized`/`out/host_debug_unopt` for the corresponding
controls, with the same toolchain and symbols. Build the unchanged source control
with identical flags. The preserved `unchanged-engine-reference-test.patch`
adapts test wiring for that control; it is not a production correction. Run
native tests under a disposable GTK display and the portal test with its owned
bus service. The standalone `renderer-retirement-test.cc` instruments the actual
renderer translation unit with synchronization barriers; it is not a timing
benchmark or a substitute for the live-engine tests.

The preserved experiment relocated a generated **test-only** schema locator
when moving binaries out of the source build. An in-place maintainer build must
keep its generated test assets; do not copy just the unittest executable and
assume the fixtures follow it. No production assertions or engine behavior were
changed for that locator repair. Full relocation/compile commands remain with
the external experiment, not in BusyMark's build workflow.

Official instructions:
[compilation](https://github.com/flutter/flutter/blob/master/docs/engine/contributing/Compiling-the-engine.md),
[debugging](https://github.com/flutter/flutter/wiki/Debugging-the-engine).
Historical complete commands, source-built binaries, debug symbols, strict
packages and A/B/C6 logs remain external. Production commands are exclusively
those in [Linux development](../../development/linux-engine.md).
