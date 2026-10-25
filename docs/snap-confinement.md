# Snap confinement

The Snap Store build uses strict confinement. BusyMark bundles Git, OpenSSH,
Typst, D2, WebKitGTK, and its other runtime dependencies rather than executing
arbitrary host programs.

The build generates and validates portable GTK icon-theme caches with the GNOME
SDK. The GNOME launcher can reuse each bundled theme's index on first launch.
These indices describe the packaged icons; graphics and media preparation still
occurs in the confined application profile.

The application plugs the standard desktop, display, audio, network, `home`,
`removable-media`, `ssh-keys`, `gpg-keys`, and `password-manager-service` interfaces. This
supports documentation projects in ordinary home-directory locations and
connected removable media. Interfaces that expose SSH keys or the system
credential store are not automatically connected. Connect only the access you
need on the installed system:

```bash
sudo snap connect busymark:ssh-keys
sudo snap connect busymark:gpg-keys
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
BusyMark opens the shared identity form and saves the identity in that
repository's local configuration. The commit draft remains intact; the user
returns to it and explicitly commits. Identity recovery never changes global
configuration or automatically repeats a possibly completed commit.

The bundled runtime is Git 2.56.0, built offline from the corresponding source
archive supplied with `busystack_git`. Its GPL license and complete source must
accompany application source distribution. The installed executable is
`$SNAP/libexec/git-runtime/bin/git`; its exec-path is explicitly set to the same
runtime's helpers. The native editor/askpass/byte-path helper is installed at
`$SNAP/libexec/busymark/busystack-git-helper`. Neither helper requires an SDK.
The runtime includes Git's libsecret helper for an explicitly configured
`credential.helper=libsecret`; repository credentials are never added to the
application's AI or Nextcloud account records. Git's other effective configured
credential helpers remain in control. SSH uses the packaged OpenSSH client;
GPG and pinentry are packaged, and `gpg-keys` controls access to GPG key files.
TLS and SSH host verification remain enabled.

The packaged GnuPG uses its documented `gpgconf.ctl` configuration to locate
the packaged helpers and keep its agent socket beneath the Snap's private
`$XDG_RUNTIME_DIR`. The `pinentry` alias selects packaged `pinentry-gnome3`.
The executables retain their upstream bytes. `GNUPGHOME` and Git's explicit
signing-tool configuration remain effective; BusyMark does not import or copy
private keys. This confined agent is separate from an existing desktop agent.
Key access alone does not grant access to the desktop's GPG-agent socket.
See the upstream [GnuPG configuration interface](https://www.gnupg.org/documentation/manuals/gnupg26/gpgconf.1.html).

The `ssh-keys` connection grants key/configuration access; it does not grant
access to the desktop SSH agent. In particular, snapd 2.77.1 on Ubuntu 26.04
denies the GNOME GCR socket at `/run/user/<uid>/gcr/ssh` to the strict Snap.
An already unlocked desktop key therefore does not establish that authentication
will work inside BusyMark. The same isolated transport succeeds outside the
Snap, while the confined client records an AppArmor socket-connect denial.
Desktop-agent interoperability remains an installed acceptance blocker; do not
disable confinement, copy private keys into repositories, or install a modified
snapd policy to work around it. See Canonical's
[SSH-agent interface discussion](https://forum.snapcraft.io/t/ssh-agent-plug-request/1250)
and the current
[`ssh-keys` interface](https://snapcraft.io/docs/reference/interfaces/ssh-keys-interface/).

Shared source archives are verified against their pinned hashes. Snapcraft
recreates their extracted siblings inside its managed part directory on each
application build, so updating a pin cannot reuse an older extraction. The
ordinary checkout helper preserves existing sibling working trees.

Strict confinement cannot promise compatibility with arbitrary host-side Git
hooks, signing programs, credential helpers, custom transports, or external
diff tools. BusyMark must report those failures rather than weakening the Snap
sandbox.

## Local installation

Install an unasserted strict build with:

```bash
sudo snap install --dangerous ./busymark_*.snap
```
