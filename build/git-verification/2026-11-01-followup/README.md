# BusyMark integration follow-up, 2026-11-01

The approved Commit/Git Log sidebars and ordinary comparison-tab structure are
unchanged. Mouse and keyboard Local History activation now deactivate the active
Git comparison without closing any comparison, clearing the selected historical
revision, saving the document or replacing its editor state. Two real-host widget
regressions open Local History before Git and switch in both directions twice,
checking retained comparison identities, revision, unsaved text, caret, undo and
zero document saves. Both fail against the original no-op handlers and pass
after the fix.

The committed CI generator invocation now uses the adapter's original
`../../../l10n/generated/app_localizations.dart` import. The README documents
the identical generation configuration. The strict shared generator is unchanged;
its exact command extracted from the committed workflow passes, and a deliberately
mismatched adapter import is rejected. Flutter localization generation leaves
the committed sources unchanged. No translations, message templates or language
catalogs were changed.

The activation fix is `00c601f`. Final runtime source is
`cf29cd125d650d831284f96439f8662bd69abc52`. The `fae6697` localization configuration correction
follows the intermediate package-import regeneration `b87f8b9`. Intermediate
verification is retained and identified separately. No history was rewritten.

Native verification exposed an additional keyboard routing problem: Git's local
dispatcher used the same intent type as application commands and swallowed tab
cycling while focus was inside Git. `cf29cd1` gives Git commands their own intent
type. The strengthened regression explicitly focuses the comparison's real
selectable region, verifies that its command scope is Git, fails before this
correction, and passes afterwards. It also verifies that F5 still reaches Git.

The initial activation source passed 601 workspace/Local History/localization
tests. Final `cf29cd1` passed four focused host regressions and 60 Git widget,
native-contract, dismissal and tab-identity tests. Localization reruns passed 24
and the official Flutter workflow suite 28.
Changed-source analysis reports no issues. Shared/host native presentation audits,
both enforcement self-tests, mixed-workspace audit, formatting, dependency-source
integrity and generated-source consistency checks pass. See [checks.json](checks.json),
the recorded command logs, and the complete 601-test log. The engine, shared
presentation, BusyFiles, source archives/checksums and third-party pins remain
unchanged. Flutter 3.47.5 / Dart 3.13.4 and their official engine remain in use.

The disk-space incident and recovery of both existing workload VMs are recorded
separately in [incident/README.md](incident/README.md). BusyData and BusyNode boot
with clean filesystem results and healthy system services; BusyNode additionally
has a supported capacity increase. Guest OS recovery is distinct from application
interaction acceptance.

The final normal release build succeeds. Its local artifact is
[busymark-cf29cd1-linux-release.tar.gz](artifacts/busymark-cf29cd1-linux-release.tar.gz),
SHA-256 `27f606ebe462e973fba84d1791cfaa712b2b2e7e8310da2b92d9ec27ec557477`.
[The runtime receipt](runtime/release-runtime-receipt.json) records the SDK,
unmodified SDK source status and every bundle file hash. The actual mapped release
engine matches the official pinned engine. These runtime revisions precede the
incident and integration evidence commits; those later commits change evidence
and documentation only. No repository was pushed and no artifact was published.

Final native checks use the running `cf29cd1` application, X11/Xvfb with Openbox,
1440×1000 at 96 dpi, DPR/text scale 1.0, English `en_US.UTF-8`, light Yaru-blue.
They open Local History first, then a real staged comparison, and reactivate both
using mouse and Ctrl+Tab/Ctrl+Shift+Tab. The document remains dirty and its exact
unsaved text is visible in Local History. Canceling application close retains
all three tabs; confirmed discard then exits naturally 0.

| Observed final state | Raw application capture |
|---|---|
| Local History opened before Git | [Local History](captures/cf29-local-history-first.png) |
| Actual HEAD/Index comparison alongside document and history tabs | [Git comparison](captures/cf29-git-active.png) |
| Ctrl+Tab reactivates Local History from focused Git | [Keyboard to history](captures/cf29-history-keyboard.png) |
| Ctrl+Shift+Tab returns to the same Git comparison | [Keyboard to Git](captures/cf29-git-keyboard.png) |
| Mouse reactivates the retained Local History tab | [Mouse activation](captures/cf29-history-mouse.png) |
| Unsaved-document close guard and canceled close | [Guard](captures/cf29-unsaved-close-guard.png), [Retained tabs](captures/cf29-close-cancel-retains-tabs.png) |
| Ordinary developer debug startup with a real comparison | [Debug](captures/cf29-ordinary-debug-comparison.png) |

The ordinary `flutter run -d linux --debug --no-pub` launch uses `lib/main.dart`,
not a probe entry point or prebuilt application shortcut. It builds, renders
the real staged comparison and exits naturally 0.
[Its receipt](runtime/debug-runtime-receipt.json) identifies the actual child
process and mapped official debug engine. The unchanged fixture receipt verifies
HEAD `5e2a71de28929e91d795cbf2677de579e712428d`, the complete index file hash and
every working-file hash after release and debug interaction. No opening or
activation operation saved a document, staged a change or moved HEAD.

[native-outcomes.json](native-outcomes.json) checks actual final process exits
and capture hashes against the recorded native interactions. The `transcripts`
directory contains lossless JSON versions of raw logs, including their original
SHA-256. Original logs and the artifact remain available locally.

Pre-final diagnostics remain separately qualified. The VM's scheduled Ubuntu
security update restarted its LXD agent and transient test services; interrupted
builds and sessions were rejected, and security updates were allowed to finish.
An overlong task runtime path caused an AT-SPI socket error; final sessions use
the short, private `/tmp/bsgit-cf29-runtime` directory through supported settings.
The Git intent interception persisted after that harness correction and was fixed
in BusyMark, with a corresponding failing/passing focused regression. A valid
Flutter-only release in an untouched generated Linux runner activated Ctrl+Tab
twice and exited 0, so the keyboard issue was not attributed to upstream.

One pre-final `fae6697` close aborted with `g_mutex_clear`; its cause was not
established. That log remains in `diagnostics/final-ui`, and the final successful
exits do not erase it or clear the older recorded native-close instability.
The final debug/release logs also retain the implicit-view removal warning.
Full AT-SPI body semantics, hardware Wayland/fractional scaling, Windows,
network/auth/signing and real IME qualification were not rerun by this focused
follow-up. The earlier platform limitations remain independently scoped.

The separate disk recovery is recorded in incident commits `4967d06` and
`0fe6482`. Final audits show BusyData and BusyNode RUNNING, BusyMax STOPPED and
the verification VM returned gracefully to STOPPED. No operator recovery is
left outstanding for the disk-space incident.
