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
* See sync-backup.sh for details and usage
* See [Simplified Server Data Backup with rsync.net](https://www.chuck-stack.org/ls/blog-rsync-net.html)

## Neovim

This repo installs Neovim from source and uses the [kickstart.nvim](https://github.com/cboecking/kickstart.nvim) configuration (fork of [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)).

### Troubleshooting

**nvim-treesitter.configs not found error**

If you see an error like `module 'nvim-treesitter.configs' not found`, this is due to a breaking change in nvim-treesitter where the default branch switched from `master` to `main` with an incompatible API rewrite.

The fix is to pin nvim-treesitter to the `master` branch. This has been applied to the kickstart.nvim fork. To update an existing installation:

```bash
rm -rf ~/.config/nvim ~/.local/share/nvim
git clone https://github.com/cboecking/kickstart.nvim.git ~/.config/nvim
```

See [kickstart.nvim issue #1802](https://github.com/nvim-lua/kickstart.nvim/issues/1802) for details.
