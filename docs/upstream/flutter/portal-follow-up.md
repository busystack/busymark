# Draft: remove synchronous settings-portal prerequisites from GTK startup

Unpublished review material. The production engine is official and unpatched.
The preserved [implementation](patches/settings-portal-async.patch),
[native tests](tests/portal-initialization-test.cc) and
[owned service](tests/portal_service.py) are upstream proposal inputs.

Exact pinned source uses synchronous session-bus connection, proxy construction
(including service activation and initial properties), then six initial Reads
on GTK. Deferring only the Reads leaves the earlier blocking dependencies.
`fl_settings.cc`, its handler and engine startup deliver these preferences to
Flutter before a usable frame; a stalled service therefore blocks the UI.

The proposed same-version correction initializes from valid local GNOME/GTK
settings, respecting explicit application preferences. Bus/proxy/read operations
are asynchronous and cancellable. Subscribe before initial reads; stage initial
authority coherently; per-key revisions prevent late read replies overwriting
newer signals. Owner changes retire prior generations. Weak contexts and one
bounded publication source avoid reviving destroyed objects or retaining the
engine. Preserve text scale, contrast, animation, clock and theme precedence.
A single genuine appearance adjustment when authority differs is acceptable.

The deterministic test holds authentication, activation, proxy properties and
Reads independently and asserts GTK progress **before release**. It covers
nondefault values, failed/missing/malformed/partial replies, updates during
initial reads, restart, repeated initialization, cancellation and pending close.
The previous corrected-engine experiments passed 21 cases per mode; unchanged
controls failed progress while the relevant synchronous request was held.
These are historical experimental results, not official-engine acceptance.

The compiled application check remains `tools/test_portal_application.py` with
the ordinary progress assertions intact. Stock widget tests cannot validate
native startup. GTK has an independent synchronous
`GetAll(org.freedesktop.portal.Inhibit)` startup dependency. It remains a
separate external-runtime blocker; no private GTK is built or proposed here.

The 2026-10-18 GitHub issue searches for `fl_settings_portal` and
`"settings portal" startup` found no matching report. This limited search is
not proof none exists; repeat the duplicate check immediately before submission.
