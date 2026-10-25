# Application packaging configuration, interpreted by unmodified GnuPG 2.4.4+.
# Keep the packaged helpers together and the agent in this Snap's private runtime.
rootdir = $SNAP/usr
sysconfdir = $SNAP/etc/gnupg
socketdir = $XDG_RUNTIME_DIR/gnupg
