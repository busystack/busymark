# Explicit Notes adoption delivery

The source implementation is committed. Candidate discovery only records evidence;
linking an uncertain draft requires authenticated fresh review and an explicit
user decision. The source archive and build artifacts are in `artifacts/`, with
commit, file and artifact hashes in its `manifest.json`.

Run `python3 verify.py artifacts/manifest.json --run-tests` with Flutter 3.47.5
on PATH to extract the committed archive, compare all recorded source bytes and
build inputs, audit discovery/adoption separation, and rerun the complete
Nextcloud regression set, including the top-level tests.

The evidence includes full Flutter and focused test logs, pre-fix failing
regressions, live HTTPS Notes 6.0.1/6.1.0 and real 423 reports, native and strict
Snap application screenshots/state/server comparisons, real denied-network
proof, recipe build provenance, installed interface/payload verification, and
credential revocation. `selected-logs.json` identifies retained command logs.
Historical failures and the reverted renderer experiment are explicitly labelled.

Release acceptance is **incomplete**: installed-Snap visualization failed on
X11 and Wayland. Both native visualization backends passed, and installed Snap
spelling, browser/keyring restart, offline durability, explicit adoption and
attachment publication passed. See `evidence/snap-acceptance-results.json` and
the development validation document for the exact failures. Public GitHub
source export for Ubuntu CI was rejected by automatic approval review;
explicit user approval was requested. No failed or blocked check is counted as
passing. Credentials and private VM/HTTPS fixture files are excluded.
