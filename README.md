# BusyMark

BusyMark is a Markdown editor for Linux with support for Writerside-compatible documentation 
projects.

[![busymark](https://snapcraft.io/busymark/badge.svg)](https://snapcraft.io/busymark)

[![Get it from the Snap Store](https://snapcraft.io/en/dark/install.svg)](https://snapcraft.io/busymark)

<p align="center">
  <img src="docs/screenshots/busymark-split-view.png" alt="BusyMark split editor and preview view" width="900">
</p>

<p align="center">
  <sub>Split view with a Writerside project tree, Markdown editor, and rendered preview.</sub>
</p>

## Features

- Open individual Markdown files.
- Open Markdown documentation folders.
- Open Writerside-compatible project folders.
- Create Writerside-compatible starter projects.
- Create Writerside Markdown and XML topics from the TOC.
- Edit and save local files.
- Preview Markdown content.
- Navigate project files, table of contents, and document outline.
- Run basic diagnostics.
- Reopen recent workspaces.
- Use native Linux desktop chrome with a GTK headerbar.

## Screenshots

<table>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/busymark-welcome.png" alt="BusyMark welcome screen">
      <br>
      <sub><b>Welcome screen</b> for creating or opening Markdown and Writerside workspaces.</sub>
    </td>
    <td width="50%">
      <img src="docs/screenshots/busymark-editor-view.png" alt="BusyMark editor view">
      <br>
      <sub><b>Editor view</b> with formatting tools and document outline navigation.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="docs/screenshots/busymark-preview-view.png" alt="BusyMark preview view">
      <br>
      <sub><b>Preview view</b> for rendered Markdown documentation.</sub>
    </td>
    <td width="50%">
      <img src="docs/screenshots/busymark-keyboard-shortcuts.png" alt="BusyMark keyboard shortcuts dialog">
      <br>
      <sub><b>Keyboard shortcuts</b> shown in the built-in shortcut reference.</sub>
    </td>
  </tr>
</table>

## Supported platforms

BusyMark is currently developed and tested for Linux desktop, especially GNOME
and Ubuntu-style GTK environments.

## Supported files and projects

BusyMark can open Markdown files such as `.md` and `.markdown`.

BusyMark opens Writerside help modules whose root contains `writerside.cfg` or
the equivalent older `project.ihp` file. Writerside support includes documented
configuration locations for topics, images, variables, categories, instances,
snippets, build configuration, API specifications, instance groups, and selected
settings metadata. Topic support includes Markdown topics, XML `.topic` files,
TOC registration, instance-specific topic titles, and custom web file names.

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

## Feedback API

The **Main menu → Report an issue** form
submits JSON to `https://busystack.org/api/feedback`. BusyMark sends no private
credentials or other API secrets; storage is handled by BusyStack.org.

Every request contains a newly generated submission UUID, `app: "busymark"`,
the application version and build number read from the current package's
generated build metadata (including Flutter build overrides),
`platform: "linux"`, the selected category, subject, detailed message, and the
optional reply email. The optional `technicalDetails` object is included after
user explicitly selects the checkbox. It contains exactly the Linux
operating-system version and the BusyMark application locale; logs, files,
document content, paths, account data, tokens, screenshots, and attachments are
never added.

```json
{
  "submissionId": "b3f44f5f-dae4-4c6e-bf56-657f35f3450a",
  "app": "busymark",
  "appVersion": "0.2.2",
  "buildNumber": "0",
  "platform": "linux",
  "category": "problem",
  "subject": "Example subject",
  "message": "Detailed feedback message",
  "replyEmail": null,
  "technicalDetails": {
    "osVersion": "Linux version string",
    "locale": "en"
  }
}
```

The endpoint returns HTTP 201 and `{"id":"<server reference ID>"}` after it
accepts a report. Validation failures, connection failures, timeouts, rate
limits, and server failures are shown without clearing the entered form.

For local development, override only the endpoint at build time. For example,
when the BusyStack.org backend is listening on port 8090:

```bash
flutter run -d linux \
  --dart-define=BUSYSTACK_FEEDBACK_ENDPOINT=http://127.0.0.1:8090/api/feedback
```

Production builds use the HTTPS endpoint by default. No credential belongs in
the Dart define or in the desktop application.

## Test

```bash
flutter analyze
flutter test
```

## Localization

BusyMark has ARB localization files for:

- Arabic (ar)
- English (en)
- Estonian (et)
- French (fr)
- German (de)
- Hindi (hi)
- Italian (it)
- Norwegian Bokmål (nb)
- Persian (fa)
- Polish (pl)
- Portuguese (pt)
- Russian (ru)
- Spanish (es)
- Ukrainian (uk)

English in `lib/l10n/app_en.arb` is the source of truth for app strings.

Target ARB files are audited for catalog parity, placeholders, plurals, and
terminology.

When changing user-facing text, update `app_en.arb`, keep every target ARB in
sync, then run:

```bash
flutter gen-l10n
flutter analyze
flutter test
```

Linux `.desktop` and AppStream metadata are localized in the repository. Snap
Store listing translations are managed outside `snap/snapcraft.yaml`.

## Build Linux Locally

Source builds require the libhandy development headers. Packaged users receive
the runtime library with BusyMark and do not install development packages.

```bash
sudo apt-get install libhandy-1-dev
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
