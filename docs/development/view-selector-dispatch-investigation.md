# Selector dispatch investigation — 2026-11-11

The selector-opening failure was reproduced and corrected in BusyMark's Linux
runner. **Acceptance remains incomplete because a separate native shutdown
check failed.**
Persisted shortcuts and a stale IDE executable were investigated before making
this attribution. The earlier socket restrictions no longer apply to this run.

## Configuration and executable evidence

Read-only inspection of the normal desktop profile and Snap x2/x3 profiles found
`shortcutOverrides: {}`. Neither `view.sidebarSelector` nor
`view.contentSelector` contained a custom or explicit null override. No user
profile or unrelated shortcut was reset.

The supplied Settings screenshot shows **Sidebar view — Ctrl+Shift+F9** and
**Content view — Ctrl+Shift+F10**. Unassigned individual view commands are the
expected result of retiring their numeric defaults.

With desktop access available, `/proc` identified the IDE Run/Debug instance as
this checkout's `build/linux/x64/debug/bundle/busymark`, launched by the official
Flutter runner from Android Studio. Its VM reported Dart 3.13.4. The user then
stopped that instance; this investigation did not terminate the user's IDE app.
The older installed Snap and release artifact were not the failing instance.

## Demonstrated native cause

A fresh isolated profile reproduced the failure. Opt-in traces followed the
actual Ctrl+Shift+F9/F10 events through the effective command registry, workspace
navigation request, attached existing menu controller and native method channel.
GTK presentation failed with BusyMark's own `invalid-arguments` response:

> single-choice groups allow at most one selected entry and require enabled entries.

The runner rejected a radio group whenever any member was unavailable. Both
selectors legitimately contain unavailable contextual views. The correction
allows disabled group members while retaining the single-selection invariant,
all other packet validation, individual GAction sensitivity, and activation-time
availability checks. Disabled mnemonic letters remain consumed by the menu.
No Flutter, Dart, Yaru or other upstream code was modified.

The follow-up also applies the renderer's document capabilities consistently to
Content View commands and menu activation. Writerside configuration documents
retain E/S/R/D assignments with Source as their only available view. Unrelated
fallback menus no longer receive selector-only mnemonic wrappers.

## Focus, Settings and keyboard verification

The existing fallback focuses its first enabled row. Both selectors retain
arrow/Enter/Escape behavior and restore their previous focus. Source's existing
text context menu handles Shift+F10 and Menu through the first-party focus
adapter; Ctrl/Alt/Meta combinations are excluded. No replacement menu or general
multi-key shortcut dispatcher was introduced.

Native acceptance uses real X11 keyboard events, the actual GTK menus, a sealed
production bundle, temporary workspaces and isolated profiles. It checks all
fixed letters and checked states, unavailable choices, a hidden sidebar,
configured tooltips, effective Settings rows, both selectors' restored Source
caret, typing/Save/Undo with exact file contents, and Shift+F10/Menu context
menus. It also checks the global Command Palette while Git is active.

The driver waits for the actual editable text to be published before sending
Save once. XTest submission alone is not editor/model completion. An earlier
focus probe had already inserted its sentinel, but sent Save before the pending
input arrived. Screenshots and a semantic completion check distinguished that
driver race from focus loss. Exact source and saved-byte assertions remain.

## Verification evidence

Current evidence is retained under `build/selector-native-final/`. The native
matrix in `native-complete/` uses `source-ready.json` and `bundle-ready/`; each case preserves its
commands, accessibility snapshots, screenshots, natural-exit result, mapped
engine identity, source/payload checks and unchanged-workspace receipt.

See [the verification report](view-selector-verification.md) for final counts
the failed native shutdown gate, matching independent compositor-abort
reproductions and captured cores, and the
unrelated pre-existing design-boundary audit finding.

`--dart-define=BUSYMARK_DEBUG_LOGGING=true` enables the existing
`[BusyMark view-selector]` trace. It records the settings path and override
presence, executable/effective bindings, F9/F10 modifiers, command/workspace
routing, controller attachment and native request/response. Logging is off by
default and does not include document text.
