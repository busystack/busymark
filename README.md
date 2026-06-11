# BusyMark

BusyMark is a Markdown editor for Linux with support for Writerside-compatible documentation 
projects.

## Features

- Open individual Markdown files.
- Open Markdown documentation folders.
- Open Writerside-compatible project folders.
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

Folder workspaces include documentation-like files such as Markdown, Writerside
topic files, `.tree`, `.cfg`, `.list`, and `.xml` files. Common resource files
such as images, PDFs, CSS, and JavaScript can appear in the project tree, but
binary resources are not opened in the text editor.

Large folders are scanned defensively. Generated and vendor directories such as
`.git`, `build`, `dist`, `node_modules`, `.dart_tool`, `.gradle`, and `target`
are skipped to keep the app responsive.

## Run From Source

Install Flutter for Linux desktop development first:

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

```bashbasicbasic
flutter analyze
flutter test
```

## Build Linux Locally

```bash
flutter build linux
```

The Linux desktop file uses the application id `io.busystack.busymark` and
installs the app icon from `assets/branding/io.busystack.busymark.png`.

## Contributing

Issues and small focused pull requests are welcome. Please keep changes aligned
with the current beta scope: local editing, Linux desktop quality, safe file
handling, and clear user-facing behavior.

## License

Apache-2.0. See [LICENSE](LICENSE).
