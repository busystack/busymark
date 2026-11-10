# Task-owned verification helpers

These helpers record the actual application and its artifact/source identities.
They are verification inputs, not production controls or an alternate Git route.
The final ordinary debug launch explicitly uses `lib/main.dart`; the keyboard
probe entry point is separately labeled in diagnostic logs.

The Flutter-only shortcut reproduction uses an official Flutter 3.47.5
`flutter create --platforms linux --no-pub --project-name shortcut_probe` project.
Its generated Linux runner is unchanged. The supplied probe Dart file replaces
only that test application's `lib/main.dart`, and its supplied pubspec uses the
same pinned SDK. Offline dependency resolution and
`flutter build linux --release --no-pub` build it without BusyMark code. Ctrl+Tab
incremented its counter twice and the process exited 0. This ruled out an
upstream shortcut defect; the application fix instead separates Git intents
from ordinary application intents.

The native recorder uses public X11/XTest and GI/AT-SPI APIs. Final desktop
sessions run under task-owned transient systemd units, with Xvfb established
before the session bus and a short private runtime directory. Security updates,
confinement and accessibility were never disabled. No SDK, engine, library,
loader or native toolkit implementation was patched.
