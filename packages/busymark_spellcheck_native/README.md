# busymark_spellcheck_native

BusyMark local Hunspell and Unicode spell-checking native component.

## Building

The package uses a Dart native-assets build hook to compile its C wrapper and
the vendored, checksum-pinned Hunspell 1.7.3 sources. It links to Pango and GLib
from the same GTK SDK/runtime as BusyMark. It does not invoke an executable or
use a host-installed Hunspell library or dictionary.

## Project structure

This template uses the following structure:

* `src`: Contains the native source code, and a CmakeFile.txt file for building
  that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* `hook`: Contains `build.dart`, which performs the native-assets build.

## Building and bundling native code

`build.dart` does the building of native components.

Bundling is done by Flutter based on the output from `build.dart`.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/busymark_spellcheck_native.h`) by `package:ffigen`.
Regenerate the bindings by running `dart run ffigen --config ffigen.yaml`.

## Invoking native code

Very short-running native functions can be directly invoked from any isolate.
BusyMark owns handles on its long-lived spelling isolate. Callers copy returned
suggestions into Dart strings before the wrapper releases their native storage.

## Flutter help

For help getting started with Flutter, view our
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
