# Summary

The purpose of this repository is to:

* Install all the necessary tools to manage iDempiere open source ERP
* Create a consistent user experience on all servers

# Installation

* Clone this repository to ~/
* Execute init.sh

# Tools and Defaults

* See init.sh for apt tools installed
* Adds vim style commands to the command line
* Creates psql defaults in .psqlrc
* Creates tmux defaults in .tmux.conf
* Installs and configures common vim tools (vim awesome)

# Usage

## tmux

Many of the chuboe idempiere scripts require either a screen or tmux session to ensure scripts will continue to run even if you are disconnected.

To create a new tmux session named 'steak':

* t

To create anew tmux session named something else:

* ta some-session-name

To quit out of a session (bash or tmux), simply type 'q'. If you are in a tmux session, it will save the contents of the session to ~/.tmux-save

## Local Configuration

Any bash statements you wish to keep local to a given server, add to file named .bash_this_server in the ~/chuboe-system-configurator/ directory. An example of something you would add to .bash_this_server:

* THIS_SERVER_HOST=' -h 10.100.2.99'

## Backup

* This repo includes a backup script to store common artifacts off-site.
* The script is split between an engine (`sync-backup.sh`) and per-scope configuration in `conf.d/`. The engine is generic; you tell it what to back up by editing or adding `conf.d/<scope>.conf` files.
* Quick start:
  1. Edit `conf.d/paths.conf` with your rsync.net credentials and host identifier.
  2. Edit `conf.d/private.conf` (and/or `conf.d/public.conf`) to list the paths you want backed up under each scope. See `conf.d/examples/` for typical entries.
  3. Run `sync-backup.sh` as root and check syslog (`grep sync-backup /var/log/syslog`) for warnings or errors.
  4. For automated execution, copy `chuboe-system-backup-cron` to `/etc/cron.d/`.
* Adding a new backup scope (e.g. "encrypted", "scratch") is purely a configuration change: drop a new `conf.d/<scope>.conf` that declares a `BU_<SCOPE>` array and appends to `SYNC_BACKUP_SCOPES`. No script edits required.
* See `sync-backup.sh` for the per-entry rsync model and layout-versioning notes.
* See [Simplified Server Data Backup with rsync.net](https://www.chuck-stack.org/ls/blog-rsync-net.html)

## Neovim

This repo installs Neovim from source and uses the [kickstart.nvim](https://github.com/cboecking/kickstart.nvim) configuration (fork of [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)).

See [refresh-kickstart-from-upstream.md](refresh-kickstart-from-upstream.md) for the recurring procedure that keeps the personal fork caught up with `nvim-lua/kickstart.nvim/master`.

### Troubleshooting

If nvim fails to load — a treesitter module error, custom plugins in `~/.config/nvim/lua/custom/plugins/` not loading, or a kickstart.nvim config out of sync — the personal fork has typically fallen behind upstream. Run the procedure in [refresh-kickstart-from-upstream.md](refresh-kickstart-from-upstream.md).
