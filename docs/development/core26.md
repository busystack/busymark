# Ubuntu 26.04 and core26

The v0.8.0 Linux jobs use GitHub's explicitly selected `ubuntu-26.04` runner.
The inventory reviewed on 2026-11-27 was Ubuntu 26.04.1, image
`20261116.202.1`, with Python 3.14 and Docker. The workflows install the GTK,
WebKitGTK, media, and desktop-session test dependencies explicitly. Flutter's
3.50 supported-platform table lists Ubuntu LTS releases through 24.04. BusyMark
requires its own compiled acceptance on 26.04 with the pinned Flutter 3.50.1
and Dart 3.14.0 SDK. [GitHub runner inventory][runner] · [Flutter supported platforms][flutter]

The shipping Snap keeps strict confinement and one amd64 build platform.
Snapcraft 9.2.2 `latest/stable` revision 19607 expanded the v0.8.0 recipe locally.
The expanded command chain selects `gpu-2604` from `mesa-2604` and the
`gnome-core26` desktop runtime. It retains explicit `audio-playback` and
`gsettings`, and binds WebKitGTK helpers and the Glycin loader directory.
`gnome-core26-sdk` revision 35 contains GTK 3.24.53, WebKitGTK 4.1 version
2.52.6, and GStreamer 1.28.2 development metadata. The installed content inspected
was `core26` revision 750, `gnome-core26` revision 35, and `mesa-2604` revision
123. These observations describe those revisions. Record actual builder and
content revisions again for the shipping artifact. [Snapcraft migration][migration] · [GNOME extension][gnome]

The recipe declares the signed HTTPS Resolute release, updates, backports and
security pockets. On 2026-11-27, the `InRelease` files for all four pockets
verified with the Ubuntu 2018 archive key
`F6ECB3762474EDA9D21B7022871920D1991BC93C`. A disposable Ubuntu 26.04.1 apt
environment resolved GTK 3 and WebKitGTK 4.1 development packages, GStreamer
1.28.2 plugins, eSpeak NG 1.52.0 and Python 3.14. [Resolute packages][resolute]

The core26 extension removes shared GNOME and graphics libraries from the
application payload. The old per-revision exclusion manifest is retired.
The runtime checks verify file and symbol resolution in the launched Snap,
including GStreamer shared and private plugins and Git's curl dependencies.
Glycin decodes the packaged SVG in the same environment that starts the
application. Build-time icon caches use the tool under
`SNAPCRAFT_GNOME_SDK`. BusyMark retains its own Yaru variants and deterministic
PDF fonts. The release check compares the engine bytes with the pinned
official release hash and records ELF notes and the exact Snap SHA-256.

## Local speech packages

Ubuntu supplies eSpeak NG and its voice data. The Snap sets
`ESPEAK_DATA_PATH` to the packaged architecture directory containing
`espeak-ng-data`. The strict Snap supplies Python 3.14 explicitly. The
standalone bundle uses Ubuntu 26.04's `/usr/bin/python3.14` and carries the same
Piper wheel set. Both load wheel files from their own application directory.
The manifest in `snap/speech-python/requirements-cp314-amd64.txt` pins the
official CPython 3.14 amd64 wheels by SHA-256. Builds retain wheel notices and
Debian package copyright files. Voice files have separate provenance and
licenses. [Piper 1.8.0 corresponding source][piper]

| Distribution | Version | License |
| --- | --- | --- |
| piper-tts | 1.8.0 | GPL-3.0-or-later |
| onnxruntime | 1.32.0 | MIT |
| numpy | 2.5.5 | BSD-3-Clause with bundled notices |
| flatbuffers | 25.12.19 | Apache-2.0 |
| packaging | 26.4 | Apache-2.0 OR BSD-2-Clause |
| pathvalidate | 3.3.1 | MIT |
| protobuf | 7.36.2 | BSD-3-Clause |

## Qualification evidence

Use the clean Snapcraft commands from the README. Install the exact output in a
disposable 26.04 desktop or VM and run the strict session gates. The decoder
checks generate known tones in all eight requested containers and verify
decoded PCM duration, signal level and frequency. This codec check is
independent of testing audible output and controls in the application.
The standalone workflow builds and exercises its archive on 26.04. Older
standalone and Snap hosts require separate installed acceptance receipts.

The native CI job calls the official `snapcraft pack --use-lxd` command with
`SNAPCRAFT_BUILD_INFO=1` set inside the runner-user command. Ubuntu 26.04's
`sudo-rs` ignores the `sudo -E` used by `snapcore/action-build@v1`. The job
retains Snapcraft's build manifest and compares the embedded recipe byte for
byte with the source recipe before installing the package. [Snapcraft build
options][build-options] · [Ubuntu sudo-rs][sudo-rs]

The locked Android path-provider dependency can discover an optional JVM when
a Linux builder happens to have a JDK. Linux uses its own path-provider
implementation. BusyMark disables that optional JNI discovery in its own
CMake configuration so standalone and Snap bundles have the same JVM-free
desktop runtime.

[runner]: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2604-Readme.md
[flutter]: https://docs.flutter.dev/reference/supported-platforms
[migration]: https://ubuntu.com/docs/snapcraft/9/how-to/change-bases/change-from-core24-to-core26/
[gnome]: https://ubuntu.com/docs/snapcraft/9/reference/extensions/gnome-extension/
[resolute]: https://packages.ubuntu.com/resolute/
[build-options]: https://ubuntu.com/docs/snapcraft/9/reference/build-environment-options/
[sudo-rs]: https://ubuntu.com/server/docs/how-to/security/user-management/#sudo-rs
[piper]: https://github.com/OHF-Voice/piper1-gpl/releases/tag/v1.8.0
