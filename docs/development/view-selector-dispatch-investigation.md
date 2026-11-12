# Selector dispatch investigation — 2026-11-11

Status: **acceptance remains incomplete**. The reported failure in the live IDE
application has not been qualified or attributed to a demonstrated native cause.
The corrections below address defects reproduced in the official headless
Flutter engine; they do not establish that the IDE's GTK menus now open.

## Configuration and executable evidence

Read-only inspection of the normal desktop profile and Snap x2/x3 profiles found
`shortcutOverrides: {}`. Neither `view.sidebarSelector` nor
`view.contentSelector` has an explicit null or custom override. The profiles
were not reset or edited by this investigation. A fresh engine probe using each
profile's input produced Ctrl+Shift+F9 and Ctrl+Shift+F10 as effective bindings.

The supplied Settings screenshot shows **Sidebar view — Ctrl+Shift+F9** and
**Content view — Ctrl+Shift+F10**. Files, Editor and the other individual view
commands show Unassigned because their numeric defaults were deliberately
retired. There is no evidence here of missing selector defaults.

The installed Snap x3 and the pre-existing release bundle are older than the
selector registrations. The debug kernel contains both IDs and shortcut labels.
The user confirmed an IDE Run/Debug launch and a full stop/start. Both discovered
Linux IDE run configurations target this checkout's `lib/main.dart`.
The runner cannot inspect the live host processes, so the executable actually
mapped by that IDE session is **not verified**. The older Snap is not presumed
to be the failing instance.

The updated Linux debug bundle was built from `lib/main.dart`. Its source and
payload receipt is sealed and verified; its kernel contains both command IDs,
both shortcut labels and the diagnostic prefix. This identifies the newly built
artifact, not the user's live IDE process.

## Reproduced defects and corrections

The existing Flutter fallback menu requested its route's focus scope without
focusing an enabled menu row. The first content mnemonic was consequently
ignored. It now focuses the first enabled row through that row's existing
InkWell. Fixed mnemonic identities, contextual disabling, native presentation,
and existing menu widgets are retained. The arrow regression now verifies that
Down advances from initially focused Files to Outline when the preceding Table
of Contents row is disabled.

A focused Source field did not handle standard Shift+F10. The ancestor focus
adapter now uses the existing context-menu release handler, after descendant
controls have had their opportunity to handle the event. It excludes Ctrl, Alt
and Meta, respects capture/composition, and opens the editable's existing menu
builder. BusyMark's text-menu presentation is shared between pointer and
keyboard entry; keyboard entry does not depend on pointer-created selection
handles or on an overlay that disappears when the menu takes keyboard focus.
The editable's context supplies the Navigator, commands and localization.
Generic editable controls use Flutter's public toolbar API. No upstream source
was modified and no replacement menu was introduced.

New application regressions cover keyboard-only Source focus, Shift+F10/Menu,
Ctrl+Shift+F10 exclusion, trigger releases, focus restoration, effective Settings
badges, custom overrides, explicit null, and preservation of an unrelated Save
binding. The existing all-mnemonic/context/localization suites are preserved.

## Dispatch tracing

`--dart-define=BUSYMARK_DEBUG_LOGGING=true` enables lines prefixed
`[BusyMark view-selector]`. Logging is off by default. The trace includes:

- the settings file and whether each selector override is absent, custom or null;
- the executable, default and effective registry bindings;
- F9/F10 key-down/up modifiers and capture state;
- command execution and workspace navigation delivery;
- menu controller attachment, pending trigger keys and menu presentation;
- the native channel request and its eventual availability/selection;
- the effective binding used by each Settings row.

These records contain command state, not document text. They allow the native
IDE run to be traced without changing or resetting its keymap.

## Verification

| Check | Result |
| --- | --- |
| Analyze `lib`, `test`, `tools` | Pass, no issues |
| Linux debug build of `lib/main.dart` | Pass |
| Sealed source/payload receipt and selector symbols | Pass |
| Resolved Git host presentation audit | Pass |
| Resolved sidebar presentation audit | Pass |
| Receipt and full-corpus evidence Python contracts | 18 pass |
| Fresh-profile production-widget diagnostic | Pass within the headless scope below |
| Affected Flutter tests | Blocked during loading; zero tests executed |
| Full Flutter suite | Attempted; zero tests executed; interrupted after socket-denied loading failures and a temporary-files quota failure |
| Ordinary/Writerside × Git/non-Git native matrix, plus custom keymap | All five blocked before application launch by D-Bus socket denial |
| Live IDE executable and native keypress trace | Blocked by the active command runner's process/socket restrictions |

The committed diagnostic at
`tools/diagnostics/view_selector_dispatch_probe.dart` boots the production
BusyMarkApp with a fresh settings file and an actual temporary Markdown file in
the official `flutter_tester`. It uses Flutter's public Linux key simulator; it
does not mock the native-menu channel. It verifies:

- both default shortcuts reach command execution, workspace navigation and the
  attached existing menu controller;
- E/S/R/D immediately select Editor/Source/Reading/Dual in the actual content
  selector fallback, with unchanged document text;
- Shift+F10 and Menu open Source's text context menu, Ctrl+Shift+F10 opens only
  Content View, and Escape restores the Source focus;
- rendered Settings badges show the defaults, then F6/F8, then an intentional
  null as Unassigned, retaining F6 and the unrelated Save → F12 override.

This engine deliberately has no GTK menu plugin. Sidebar dispatch reaches the
native request and returns MissingPlugin; **sidebar opening and its subsequent
mnemonics are not accepted by this diagnostic**. Synthetic Flutter events do
not qualify as native/OS keyboard acceptance. The existing native driver and
canonical test gates have not been bypassed or weakened.

To repeat the diagnostic with the verified official writable SDK copy:

```sh
TASK_FLUTTER_SDK="$PWD/build/verification-tools/flutter-sdk"
"$TASK_FLUTTER_SDK/bin/flutter" build bundle --debug --no-pub \
  --target-platform=linux-x64 \
  --target=tools/diagnostics/view_selector_dispatch_probe.dart \
  --asset-dir=build/selector-dispatch-investigation/diagnostic-assets
XDG_DATA_HOME="$PWD/build/selector-dispatch-investigation/isolated-data" \
XDG_CONFIG_HOME="$PWD/build/selector-dispatch-investigation/isolated-config" \
  "$TASK_FLUTTER_SDK/bin/cache/artifacts/engine/linux-x64/flutter_tester" \
  --disable-vm-service \
  --icu-data-file-path="$TASK_FLUTTER_SDK/bin/cache/artifacts/engine/linux-x64/icudtl.dat" \
  --flutter-assets-dir=build/selector-dispatch-investigation/diagnostic-assets \
  build/selector-dispatch-investigation/diagnostic-assets/kernel_blob.bin
```

Evidence is retained in `build/selector-dispatch-investigation/`: diagnostic,
registry, analysis/build/audit/test logs, the sealed receipt, and the native
matrix's per-case D-Bus errors. The failed full-suite compiler's own 4.5 GiB
temporary directory was removed after stopping that run; no SDK, user profile
or unrelated temporary directory was removed.

After the user enabled full access, a fresh check still received EPERM for
`/run/user/1000/bus`, `/run/user/1000/wayland-0` and localhost socket creation.
The command runner still identified its policy as managed/restricted. Automatic
approval review rejected the read-only D-Bus escalation because its active
configuration has `sandbox_approval: false`. Native acceptance and passing
affected/full tests require that permission change to reach the active runner.
The remaining native failure must be reproduced and corrected there before
this work can be reported complete. No application changes were pushed or
published.
