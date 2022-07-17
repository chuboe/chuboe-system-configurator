#!/bin/bash

# wishlist
# - create symbolic links to .psqlrc and inputrc

sudo apt update
sudo apt install -y vim git tree tmux fd-find wget sysstat curl

# if you want to update the below files, add anything to the ./init.sh. Example: ./init.sh REDO

if [[ $1 == "" ]]
then
    # install vim awesome as base
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh

    # install tmux plugin manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # install cheatsheet command line tool
    sudo snap install cheat
fi

mkdir -p ~/.psql_history.d
cp my_configs.vim ~/.vim_runtime/.
cp .psqlrc ~/.
cp .inputrc ~/.
cp .alacritty.yml ~/.
cp .tmux.conf ~/.

# https://tmuxcheatsheet.com

if [[ $1 == "" ]]
then
    echo source \~/chuboe-system-configurator/.my_bash >> ~/.bashrc
fi

# create and copy over backup artifacts
FILE=~/chuboe-system-backup/sync-backup.sh
if [[ -f "$FILE" ]]; then
    echo "$FILE exists... skipping..."
else
	mkdir -p ~/chuboe-system-backup/
	cp sync-backup.sh ~/chuboe-system-backup/.
	cp chuboe-system-backup-cron ~/chuboe-system-backup/.
    # Draft a last update version to prevent the first rsync from failing
    touch ~/chuboe-system-backup/sync-lastupdate.txt
fi


### system stats ###
# execute this file if you wish the system to automatically collect statistics
# sudo sed -i "s|ENABLED=.*|ENABLED=\"true\"|g" /etc/default/sysstat

# reference: https://www.youtube.com/watch?v=_4WVPSfGqos

# usage after enabled:
# see files: ls -l /var/log/sysstat/
# see statistics for 26th of month: sudo sar -u -f /var/log/sysstat/sa26
