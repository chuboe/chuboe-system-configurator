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
