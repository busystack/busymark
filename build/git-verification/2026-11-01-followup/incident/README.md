# Verification disk-space incident recovery, 2026-11-01

This incident is separate from the Local History activation and localization
corrections. The earlier verification exhausted host disk space and disrupted
two pre-existing VMs. At this follow-up's initial audit BusyData was STOPPED and
BusyNode was in LXD Error; the verification VM and BusyMax were STOPPED.

BusyNode's ordinary `lxc stop --timeout=30` failed because LXD cannot cleanly shut
down an instance in Error. A supported `lxc stop --force` cleared that state,
followed by `lxc start`. No volume was deleted or replaced. The guest's initial
boot fsck recovered its ext4 journal and reported the filesystem clean.
Journald retained the old unclean journal by renaming it; the first-recovery
boot log records that observation. No current-boot error-level journal entries,
failed system services, or pending package repairs were reported.

BusyNode initially had only 107 MiB free inside its 10 GiB root disk. Supported
`apt-get clean` removed downloaded package archives, leaving about 404 MiB;
installed packages and the existing BusyNode builds were retained. Its inherited
LXD root device was then overridden with `size=16GiB`. A graceful stop/start
applied the new capacity, and the guest's existing cloud image expanded the
partition/filesystem through its normal boot handling. The next boot filesystem
check was clean. Its final root filesystem has about 6.1 GiB free.

BusyData started normally. Its boot filesystem check reports clean, the root
mount is read/write, `systemctl is-system-running` reports running, there are no
failed units or current-boot error-level journal entries, and `dpkg --audit` is
empty. Its existing busydata x32 installation remains installed; neither it nor
its application data was replaced. Its unchanged 32 GiB root disk has about
3.1 GiB free.

Both affected VMs were restored to RUNNING, their state before the original
incident. These checks establish guest OS recovery, boot filesystem results and
service health. They do not assert recovery of lost process memory or qualify
either application's desktop interactions. The attached command logs contain
the actual guest results, including filesystem identities and block counts.
The final independent audit at 10:53 UTC again reports both guests running,
read/write root mounts, clean boot filesystem results, no failed units and no
pending package repairs.

Committed JSON transcripts preserve the exact raw command output and its SHA-256,
including the filesystem tools' trailing spaces. The original `.log` files remain
beside them in the local evidence directory.

Follow-up application verification uses the existing BusyFiles verification VM
and its retained official SDK/dependencies. It checks at least 3 GiB guest free
space before each recorded verification phase, monitors host/guest free space,
and runs heavy tests/builds sequentially. The workspace disk initially had about
42 GiB free; the offered additional disk had about 15 GiB free and was not
needed. No unrelated caches, source trees, VM volumes, or installed software were
deleted. No security, confinement, accessibility, toolchain, or dependency
modifications were used for recovery.

The application verification VM was shut down gracefully and is STOPPED again.
BusyMax remained STOPPED. The final state of all four pre-existing VMs therefore
matches the state preceding the disk-space incident.
