# Snap confinement

The Snap Store build uses strict confinement. BusyMark bundles Git, OpenSSH,
Typst, D2, WebKitGTK, and its other runtime dependencies rather than executing
arbitrary host programs.

The application plugs the standard desktop, display, audio, network, `home`,
`removable-media`, `ssh-keys`, and `password-manager-service` interfaces. This
supports documentation projects in ordinary home-directory locations and
connected removable media. Interfaces that expose SSH keys or the system
credential store are not automatically connected. Connect only the access you
need on the installed system:

```bash
sudo snap connect busymark:ssh-keys
sudo snap connect busymark:password-manager-service
```

BusyMark stores AI provider keys and Nextcloud Notes app passwords in the system
credential store through libsecret. Saving, reading, or removing either kind of
credential in a strict Snap requires the `password-manager-service` connection.
It grants access to the session's password manager, so make that choice only on a
trusted installation. Nextcloud credentials have a separate namespace; an
unavailable or locked credential store has no plaintext fallback. See
[Nextcloud Notes](development/nextcloud-notes.md) for the authentication contract.

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
