# Snap confinement

The Snap Store build uses strict confinement. BusyMark bundles Git, OpenSSH,
Typst, D2, WebKitGTK, and its other runtime dependencies rather than executing
arbitrary host programs.

The application plugs the standard desktop, display, audio, network, `home`,
`removable-media`, and `ssh-keys` interfaces. This supports documentation
projects in ordinary home-directory locations and connected removable media.
Interfaces that expose sensitive SSH material are controlled by snapd and may
require an explicit connection on the installed system.

## Git author identity

Git inside a strict Snap has a private home directory and cannot assume that a
host-level `~/.gitconfig` is visible. When a commit has no author name or email,
BusyMark opens a native identity form, saves the identity through bundled Git,
and retries the original commit. The user never needs to run `git config` from
a terminal.

The form can save the identity for only the current repository or globally.
Inside the Snap, global scope means every repository opened by BusyMark because
the configuration is stored in BusyMark's Snap data directory. Repository scope
writes the standard local Git configuration for that repository.

Strict confinement cannot promise compatibility with arbitrary host-side Git
hooks, signing programs, credential helpers, custom transports, or external
diff tools. BusyMark must report those failures rather than weakening the Snap
sandbox.

## Local installation

Install an unasserted strict build with:

```bash
sudo snap install --dangerous ./busymark_*.snap
```
