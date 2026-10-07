# Installed strict-Snap acceptance: final KVM run

The unchanged recipe-built Snap passed all 23 visualization checks on X11 and
Wayland twice after configuring a functioning disposable desktop session.
Spelling passed 20 checks for online installation, refresh/offline X11 restart,
and offline Wayland restart. Wayland visualization also ran with the Snap's
network interface disconnected. `results.json` indexes the successful reports;
`acceptance/installed-identity-final.log` proves the installed bytes, recipe,
runtime revisions, interfaces, and enforced AppArmor profile.

The guest was Ubuntu 24.04.5, kernel 6.8.0-142, KVM with 4 CPUs/4 GiB. The official
cloud image checksum is in `results.json`. The disposable user was `tester`.
No Nextcloud account or production profile was used in this additional VM.
Browser Login Flow, libsecret/restart, actual uncertain-creation confirmation,
attachment publication and denied-network recovery already passed on this exact
Snap, recorded in the parent evidence directory.

The numbered shell scripts are the existing `.github/workflows/flutter-linux.yml`
Snap checks. Only its runner temporary directory and selected Snap path are
substituted. They retain every assertion and timeout. The exact installed package
SHA-256 is `2b7c2a7b91a9aa7cbb7f23d35186e59a46173446b95ca9a14ddb5f667ca592ce`.

After normal Ubuntu cloud-init setup:

```sh
sudo snap install --dangerous /home/tester/package.snap
sudo snap connect busymark:password-manager-service
# Use the normal systemd user session, with /run/user/1000/bus.
bash 01-verify-gtk-svg-icon-loader.sh
bash 02-verify-shared-runtimes-packaged-tools-media-and-resources.sh
bash 03-install-one-strict-snap-dictionary-and-verify-refresh-offline-use.sh
```

The initial bare VM lacked a desktop activation environment. A private
`dbus-run-session` failed Snap cgroup creation (`acceptance-session-fixture/`).
The normal user session fixed that. Its GTK portal then could not start on a
display and waited repeatedly for service timeouts; the initial X11 render
timed out (`acceptance/04-*/`). The desktop setup was completed with:

```sh
Xvfb :97 -screen 0 1280x1024x24 -nolisten tcp &
dbus-update-activation-environment --systemd DISPLAY=:97 XDG_CURRENT_DESKTOP=GNOME
mkdir -p ~/.config/xdg-desktop-portal
cp acceptance/portals.conf ~/.config/xdg-desktop-portal/portals.conf
systemctl --user restart xdg-desktop-portal-gtk.service xdg-desktop-portal.service
gdbus call --session --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.Read org.gnome.desktop.interface color-scheme
bash 04-exercise-strict-snap-visualization-and-pdf-paths-under-x11.sh
bash 05-exercise-strict-snap-spelling-and-visualization-under-wayland.sh
bash repeat-acceptance.sh
```

The copied configuration is `acceptance/portals.conf`; the Settings result and
activation environment are beside it. The numbered scripts create their own
X11/Wayland displays. Display :97 keeps the desktop portal available. No AppArmor
rule, application timeout or assertion was relaxed. The experimental
`NO_AT_BRIDGE=1` run is retained separately; both final runs and repeats omit it.
The new fixture failures do not establish the cause of every older TCG error.
`snap-acceptance-before-kvm.json` preserves that earlier incomplete status.

`acceptance/rendered-exports.tar.gz` contains the resulting HTML/PDF exports;
each successful backend directory also contains its PDF. `status.tsv` retains
both initial failed and subsequent successful exit statuses. The configured X11
run is recorded by its successful report and command log; the repeat took 10s.
The configured Wayland sequence took 16s and its repeat took 18s.

Public CI publication was approved but the GitHub connector returned 403 and
existing SSH authentication failed. `public-ci-access.json` records that
unavailable route; no remote branch, PR, upload or CI success is claimed.
The authorized VM completed acceptance. Private VM keys, disks and Snap cookies
are excluded, and the VM is destroyed after evidence collection.
