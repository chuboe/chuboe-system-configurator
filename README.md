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

## Capability Map

`init.sh` bootstraps a machine and also installs ongoing capabilities. Capabilities that need re-running on an existing server live in their own script, callable on demand:

| Capability | Script | Run it again when... |
|---|---|---|
| Neovim binary | `install-neovim.sh` | you want the latest `stable` |
| Neovim config | `install-kickstart.sh` | you want upstream master, or edited something in `nvim/` |
| Backup | `install-backup.sh` | you edited `sync-backup.sh` or `conf.d/*` |
| Backup data | `sync-backup.sh` | nothing — it runs from cron |

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
* Adding a new backup scope (e.g. "encrypted", "scratch") is purely a configuration change: drop a new `conf.d/<scope>.conf` that declares a `BU_<SCOPE>` array and appends to `SYNC_BACKUP_SCOPES`. No script edits required.
* **Operator workflow (the single source of truth) lives in the deployed readme on each host at `/opt/chuboe-system-backup/readme.md`** — created by `install-backup.sh` during `init.sh`, or by running `install-backup.sh` standalone. After install, read that file for the post-install steps (paths.conf credentials, root SSH key, scope entries, cron, etc.). Keep it up to date as the source of truth; do not duplicate its steps here.
* See `sync-backup.sh` for the per-entry rsync model and layout-versioning notes.
* See [Simplified Server Data Backup with rsync.net](https://www.chuck-stack.org/ls/blog-rsync-net.html)

## Neovim

This repo installs Neovim from source at its moving `stable` tag and configures it with upstream [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) — no personal fork. Our personalizations live in [`nvim/`](nvim/) here and are copied onto the upstream config by `install-kickstart.sh`.

Two scripts own this capability, and both run standalone so an existing server can be kept current without re-running `init.sh`:

```bash
./install-kickstart.sh --update   # config -> upstream master, then re-apply nvim/
./install-neovim.sh               # binary -> latest stable (no-op if unchanged)
```

See [refresh-kickstart-from-upstream.md](refresh-kickstart-from-upstream.md) for the layout, how to edit a personalization, and how to migrate a host still on the old fork.
