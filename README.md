# BusyMark

BusyMark is a Markdown editor for Linux with support for Writerside-compatible documentation 
projects.

[![busymark](https://snapcraft.io/busymark/badge.svg)](https://snapcraft.io/busymark)

[![Get it from the Snap Store](https://snapcraft.io/en/dark/install.svg)](https://snapcraft.io/busymark)

## Features

- Open individual Markdown files.
- Open Markdown documentation folders.
- Open Writerside-compatible project folders.
- Create Writerside-compatible starter projects.
- Edit and save local files.
- Preview Markdown content.
- Navigate project files, table of contents, and document outline.
- Run basic diagnostics.
- Reopen recent workspaces.
- Use native Linux desktop chrome with a GTK headerbar.

## Supported platforms

BusyMark is currently developed and tested for Linux desktop, especially GNOME
and Ubuntu-style GTK environments.

## Supported files and projects

BusyMark can open Markdown files such as `.md`, `.markdown`, `.mdown`, and
`.mkd`.

BusyMark opens Writerside help modules whose root contains `writerside.cfg` or
the equivalent older `project.ihp` file. Writerside support includes documented
configuration locations for topics, images, variables, categories, instances,
snippets, build configuration, API specifications, instance groups, and selected
settings metadata.

Folder workspaces include documentation-like files such as Markdown, Writerside
topic files, `.tree`, `.cfg`, `.list`, and `.xml` files. Common resource files
such as images, PDFs, CSS, and JavaScript can appear in the project tree, but
binary resources are not opened in the text editor.

Large folders are scanned defensively. Generated and vendor directories such as
`.git`, `build`, `dist`, `node_modules`, `.dart_tool`, `.gradle`, and `target`
are skipped to keep the app responsive.

## Run From Source

1. [Install Flutter](https://docs.flutter.dev/install)

2. Run the application:

```bash
flutter doctor
flutter pub get
flutter run -d linux
```

Open a file or folder from the command line:

```bash
flutter run -d linux -- /path/to/README.md
flutter run -d linux -- /path/to/docs
```

## Test

```bash
flutter analyze
flutter test
```

## Build Linux Locally

```bash
flutter build linux
```

The Linux desktop file uses the application id `io.busystack.busymark` and
installs the app icon from `assets/branding/busymark_logo.svg`.

## Contributing

Issues and small focused pull requests are welcome. Please keep changes aligned
with the current beta scope: local editing, Linux desktop quality, safe file
handling, and clear user-facing behavior.

## License

Apache-2.0. See [LICENSE](LICENSE).
