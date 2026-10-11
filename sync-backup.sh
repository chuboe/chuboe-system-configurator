#!/bin/bash

#### Summary ####
# This script exists to make backing up all desktop and server artifacts simple and easy from a single location.

# Notes:
# While this script comes with the github.com/chuboe/chuboe-system-configurator/, it can be used in isolation if needed
# Configuration lives in conf.d/, NOT in this script -- see "Architecture" below.

# Architecture
#   sync-backup.sh            generic engine. Sources conf.d/*.conf, then
#                             iterates SYNC_BACKUP_SCOPES and rsyncs every
#                             entry in each scope's BU_<SCOPE> array.
#   conf.d/paths.conf         remote connection + local path variables
#                             (sourced first; do not rename).
#   conf.d/<scope>.conf       one associative array (BU_<SCOPE>) per file,
#                             plus `SYNC_BACKUP_SCOPES+=(<scope>)`.
#   conf.d/examples/          copy-paste fodder. NOT sourced.
#
# Shellcheck: `shellcheck sync-backup.sh` is clean. To also analyze the
# conf files that the engine sources, run `shellcheck -x sync-backup.sh`.
# Conf files declare variables/arrays that are intentionally consumed
# by the engine after sourcing, so SC2034 ("appears unused") warnings
# on conf files in isolation are expected false positives.
#
# v02 layout: per-scope, per-key rsync into
#   $RSYNC_BU_PATH/<scope>/<key>/
# so --delete cannot cross-contaminate between entries, and a missing or
# broken-symlink source is skipped (with a syslog warning) instead of
# being staged as a hole that rsync would later walk into.

# Minimal Instructions
# 1. Execute create-root-ssh-key.sh as root to create a local ssh key and test connection
# 2. Edit conf.d/paths.conf with your rsync.net credentials
# 3. Edit conf.d/private.conf (and/or copy conf.d/examples/private.conf.example entries in)
# 4. Run this script as root and confirm there are no errors

# Automated execution
# It is expected that you will add this script to a cronjob for automatic execution. See: chuboe-system-backup-cron

function graceful_exit
{
    # Catastrophic-failure handler. Logs to the same sync-backup syslog tag
    # the rest of the script uses (the v01 reference to a local log file
    # was never set, so it never worked) and echoes to stdout for cron /
    # interactive runs.
    local stamp
    stamp=$(TZ=US/Eastern date '+%m/%d/%Y %H:%M:%S EST.')
    printf 'Exiting due to an error occuring at %s\nError: %s\n' \
        "$stamp" "$1" | logger -t sync-backup
    echo "Exiting due to an error occuring at $stamp"
    echo "Error: $1"
    exit 1
}

# Back up a single source path (file or directory) into a per-key destination
# subdir at the rsync.net remote. Skips silently (with a syslog record) if
# the source is missing or a broken symlink -- one bad BU_* entry must not
# poison --delete for other entries or the whole backup.
#
# Each entry gets its own rsync invocation with its own --delete scope, so
# deletions and broken-link failures are isolated. This is the v02 model;
# see the script header for context.
backup_one_entry() {
    local src="$1"
    local remote_base="$2"   # e.g. $RSYNC_BU_PATH/private/id-archive (no trailing slash)
    local label="$3"         # e.g. "private/id-archive" -- for log lines

    if [ ! -e "$src" ]; then
        # -e follows symlinks, so a broken symlink (target gone) is detected
        # here and we never rsync it. The destination subdir from any previous
        # good run is left in place -- which is the safe default for a backup.
        logger -t sync-backup -p user.warning \
            "skipping $label: source missing or broken symlink: $src"
        return 0
    fi

    if [ -d "$src" ]; then
        # Directory source: trailing slash on both sides so the contents of
        # $src land directly inside $remote_base, and --delete operates on
        # the contents (not on $remote_base itself).
        rsync -rptgoDL --delete \
            "$src/" "$RSYNC_BU_USER@$RSYNC_BU_URL:$remote_base/"
    else
        # File source: no trailing slash on either side so the file lands
        # as $remote_base (a single file at the remote). --delete has
        # nothing to scan; that's fine.
        rsync -rptgoDL --delete \
            "$src" "$RSYNC_BU_USER@$RSYNC_BU_URL:$remote_base"
    fi

    local rc=$?
    if [ $rc -ne 0 ]; then
        logger -t sync-backup -p user.err \
            "rsync failed for $label (exit $rc): $src"
    fi
    return $rc
}

#### Variables ####
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_OSUSER=$(id -u -n)
cd "$SC_SCRIPTPATH" || graceful_exit "could not cd to $SC_SCRIPTPATH"

if [ "$SC_OSUSER" != "root" ]; then
    echo  
    graceful_exit "Error: run script as root. Switch to root using: sudo su"
fi


#### Source Configuration ####
# Default conf dir is alongside the script. Override with
# SYNC_BACKUP_CONF_DIR=/some/other/path for non-default deployments.
CONF_DIR="${SYNC_BACKUP_CONF_DIR:-$SC_SCRIPTPATH/conf.d}"

if [ ! -d "$CONF_DIR" ]; then
    graceful_exit "configuration directory not found: $CONF_DIR (set SYNC_BACKUP_CONF_DIR to override)"
fi
if [ ! -f "$CONF_DIR/paths.conf" ]; then
    graceful_exit "missing required configuration: $CONF_DIR/paths.conf"
fi

# paths.conf first so per-scope confs can reference $OPT_BACKUP_DIR,
# $USER_HOME, $RSYNC_BU_*, etc.
# shellcheck disable=SC1091
# $CONF_DIR is dynamic (overridable via SYNC_BACKUP_CONF_DIR), so a
# static source link is not possible. The conf file is still analyzed
# when shellcheck is invoked with `-x`.
source "$CONF_DIR/paths.conf"

# Source every scope conf. paths.conf is excluded -- already loaded.
# Lexical order is fine here because each scope conf is self-contained.
for conf in "$CONF_DIR"/*.conf; do
    [ -e "$conf" ] || continue                 # no matches
    [ "$(basename "$conf")" = "paths.conf" ] && continue
    # shellcheck disable=SC1090  # per-iteration source can't be hinted; SC1090 is the right tool.
    # shellcheck source-path=SCRIPTDIR
    source "$conf"
done


#### Validate Configuration ####
# Catch config errors before they silently produce empty backups. Each
# declared scope should have at least one entry; an empty array is almost
# always a typo or a forgotten migration step.
if [ "${#SYNC_BACKUP_SCOPES[@]}" -eq 0 ]; then
    graceful_exit "no SYNC_BACKUP_SCOPES declared; check that your conf.d/*.conf files end with 'SYNC_BACKUP_SCOPES+=(...)'"
fi

for scope in "${SYNC_BACKUP_SCOPES[@]}"; do
    declare -n _arr="BU_${scope^^}"
    if [ "${#_arr[@]}" -eq 0 ]; then
        logger -t sync-backup -p user.warning \
            "scope '$scope' declared but has no entries; check conf.d/$scope.conf"
    fi
done


#### Pre-create Remote Parent Dirs ####
# Build the per-scope parent dirs we need on the remote. rsync will
# auto-create the leaf for each entry but not the intermediate
# $RSYNC_BU_PATH/<scope>/, so we mkdir those up front.
remote_parents=()
for scope in "${SYNC_BACKUP_SCOPES[@]}"; do
    remote_parents+=("$RSYNC_BU_PATH/$scope")
done

if [ "${#remote_parents[@]}" -gt 0 ]; then
    # shellcheck disable=SC2029
    # RSYNC_BU_PATH is intentionally expanded on the client side -- we
    # want this client's value used on the remote.
    if ! ssh "$RSYNC_BU_USER@$RSYNC_BU_URL" "mkdir -p ${remote_parents[*]}"; then
        logger -t sync-backup -p user.err \
            "could not reach $RSYNC_BU_URL to create remote parent dirs; aborting"
        echo "Could not reach $RSYNC_BU_URL. Aborting."
        exit 1
    fi
fi


#### Backup Entries ####
# One rsync per BU_<scope> entry. Each entry's --delete operates only
# on its own remote subdir, so a missing or broken BU_* entry cannot
# interfere with another entry's delete semantics. Per-entry failures
# are recorded in syslog and counted toward the final exit status.
BACKUP_FAILURES=0
TOTAL_ENTRIES=0

for scope in "${SYNC_BACKUP_SCOPES[@]}"; do
    declare -n _bu="BU_${scope^^}"
    for key in "${!_bu[@]}"; do
        echo "$scope/$key ${_bu[$key]}"
        backup_one_entry "${_bu[$key]}" "$RSYNC_BU_PATH/$scope/$key" "$scope/$key" \
            || BACKUP_FAILURES=$((BACKUP_FAILURES + 1))
        TOTAL_ENTRIES=$((TOTAL_ENTRIES + 1))
    done
done


#### Summary ####
# Surface a final pass/fail record so cron / monitoring can see whether
# the run completed cleanly. Broken-symlink skips do NOT count as
# failures -- they are expected operator-fixable config drift.
if [ "$BACKUP_FAILURES" -gt 0 ]; then
    logger -t sync-backup -p user.err \
        "backup completed with $BACKUP_FAILURES of $TOTAL_ENTRIES entries failing; see earlier log lines"
    echo
    echo "Backup completed with $BACKUP_FAILURES of $TOTAL_ENTRIES entries failing. See syslog tag 'sync-backup' for details."
    echo "to inspect: ssh $RSYNC_BU_USER@$RSYNC_BU_URL ls $RSYNC_BU_PATH"
    exit 1
fi

logger -t sync-backup -p user.info \
    "backup completed: $TOTAL_ENTRIES entries OK"
echo
echo "Backup completed: $TOTAL_ENTRIES entries OK."
echo "to test: ssh $RSYNC_BU_USER@$RSYNC_BU_URL ls $RSYNC_BU_PATH"
echo