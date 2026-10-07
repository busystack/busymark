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

Release acceptance is **complete**. The same recipe-built strict Snap passed
installed X11 and Wayland visualization (23 checks each, repeated successfully)
in a disposable Ubuntu KVM desktop. Installed spelling passed 20 checks per
run, including refresh and denied-network restart. Browser/keyring restart,
offline durability, explicit adoption and attachment publication had already
passed against this identical package. See `evidence/installed-kvm/README.md`
for the desktop setup, commands and results. Earlier failures remain historical
evidence and are not counted as passes.

Public CI publication was explicitly approved, but the GitHub integration
returned HTTP 403 and existing SSH authentication was unavailable. No branch
or PR was created. The authorized disposable VM completed installed acceptance.
Credentials and private VM/HTTPS fixture files are excluded. `artifacts/manifest.json`
identifies the final commit, current archives, exact build hashes and checks;
superseded archives are kept separately under `artifacts/historical/`.
