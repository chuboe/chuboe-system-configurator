#!/bin/bash
# install-backup.sh -- idempotent deploy of chuboe backup script + config.
#
# Source repo location is auto-detected (the directory holding this
# script). The destination is /opt/chuboe-system-backup by default;
# override with BACKUP_DEST=/some/other/path for non-default deployments.
# Run as root or with sudo.
#
# Idempotent: re-running overwrites code files, refreshes the example
# confs, and preserves any operator-edited live confs. On first install
# on an empty destination, BU_REMOTE_NAME in conf.d/paths.conf is set to
# this host's hostname (override with BACKUP_HOSTNAME=foo if you want a
# different remote subdir name).
#
# After install, edit /opt/chuboe-system-backup/conf.d/paths.conf to
# set RSYNC_BU_USER and RSYNC_BU_URL.

set -euo pipefail

DEST="${BACKUP_DEST:-/opt/chuboe-system-backup}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME_VAL="${BACKUP_HOSTNAME:-$(hostname)}"

# require root
if [ "$(id -u)" != "0" ]; then
    echo "Error: must run as root (use sudo)" >&2
    exit 1
fi

echo "==> Installing chuboe backup"
echo "    From: $SRC"
echo "    To:   $DEST"
echo "    Host: $HOSTNAME_VAL"

# destination dirs
mkdir -p "$DEST/conf.d"

# --- code files (always overwrite, idempotent) ---
echo "==> Copying script + cron + helper"
install -m 0755 "$SRC/sync-backup.sh"           "$DEST/sync-backup.sh"
install -m 0644 "$SRC/chuboe-system-backup-cron" "$DEST/chuboe-system-backup-cron"
install -m 0755 "$SRC/create-root-ssh-key.sh"    "$DEST/create-root-ssh-key.sh"

# --- live confs (copy only if missing, to preserve operator edits) ---
# On first install on an empty destination, paths.conf is fresh and we
# stamp BU_REMOTE_NAME with this host's hostname so the remote layout
# is per-host out of the box. If paths.conf already existed (operator
# may have edited it), leave it alone -- re-running is a no-op.
echo "==> Deploying live confs (only if missing)"
JUST_CREATED_PATHS=no
for f in paths.conf private.conf public.conf; do
    if [ ! -e "$DEST/conf.d/$f" ]; then
        install -m 0644 "$SRC/conf.d/$f" "$DEST/conf.d/$f"
        [ "$f" = "paths.conf" ] && JUST_CREATED_PATHS=yes
    fi
done

if [ "$JUST_CREATED_PATHS" = "yes" ]; then
    echo "==> Setting BU_REMOTE_NAME=$HOSTNAME_VAL in fresh paths.conf"
    sed -i "s|^BU_REMOTE_NAME=.*|BU_REMOTE_NAME=$HOSTNAME_VAL|" \
        "$DEST/conf.d/paths.conf"
fi

# --- example confs (always refresh; documentation only) ---
echo "==> Refreshing conf.d/examples/"
rm -rf "$DEST/conf.d/examples"
mkdir -p "$DEST/conf.d/examples"
for f in "$SRC"/conf.d/examples/*; do
    [ -e "$f" ] || continue
    install -m 0644 "$f" "$DEST/conf.d/examples/"
done

# --- supporting files (only if missing) ---
[ -e "$DEST/sync-lastupdate.txt" ] || touch "$DEST/sync-lastupdate.txt"
if [ ! -e "$DEST/readme.md" ]; then
    cat > "$DEST/readme.md" <<EOF
# chuboe-system-backup deployment

Installed by install-backup.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ).
Hostname at install time: $HOSTNAME_VAL

Edit conf.d/paths.conf to set RSYNC_BU_USER and RSYNC_BU_URL.
Run $DEST/create-root-ssh-key.sh as root and follow its printed
instructions to install the public key on your rsync.net sub-account.
Without this step, the first backup or cron run will fail with a
publickey authentication error.
Edit conf.d/private.conf (and public.conf) to list paths to back up.
See conf.d/examples/ for typical entries.

Run the script with: sudo $DEST/sync-backup.sh
Enable cron with:    sudo cp $DEST/chuboe-system-backup-cron /etc/cron.d/
EOF
fi

echo
echo "==> Done."
echo
echo "Installed files:"
ls -la "$DEST"
echo
echo "conf.d/:"
ls -la "$DEST/conf.d/"
echo
echo "Next steps:"
echo "  1. Edit $DEST/conf.d/paths.conf:"
echo "       - Set RSYNC_BU_USER and RSYNC_BU_URL to your rsync.net login/host."
echo "       - Verify BU_REMOTE_NAME=$HOSTNAME_VAL matches what you want on the remote."
echo "  2. Edit $DEST/conf.d/private.conf (and/or public.conf) to list paths to back up."
echo "       See $DEST/conf.d/examples/ for typical entries."
echo "  3. Test: sudo $DEST/sync-backup.sh"
echo "  4. Watch syslog: tail -f /var/log/syslog | grep sync-backup"
echo "  5. Enable cron (optional): sudo cp $DEST/chuboe-system-backup-cron /etc/cron.d/"