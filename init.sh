#!/bin/bash

# wishlist
# - create symbolic links to .psqlrc and inputrc

sudo apt update
sudo apt install -y man vim git tree tmux fd-find wget sysstat curl ufw rsync zip pkg-config gcc cmake libssl-dev

# if you want to update the below files, add anything to the ./init.sh. Example: ./init.sh REDO

if [[ $1 == "" ]]
then
    # install vim awesome as base
    echo HERE install vim-awesome
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh

    # install tmux plugin manager
    echo HERE install tmux plugin manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # install rust eco system
    echo HERE install rust eco
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    # install nushell
    echo HERE install nushell
    cargo install nu --locked

    # install starship prompt
    echo HERE install starship
    cargo install starship --locked
fi

mkdir -p ~/.psql_history.d
mkdir -p ~/.config/
cp my_configs.vim ~/.vim_runtime/.
cp .psqlrc ~/.
cp .inputrc ~/.
cp .alacritty.yml ~/.
cp .tmux.conf ~/.
cp starship.toml ~/.config/starship.toml

# https://tmuxcheatsheet.com

if [[ $1 == "" ]]
then
    echo HERE update .bashrc
    echo source \~/chuboe-system-configurator/.my_bash >> ~/.bashrc
    # starship init => must be last in file
    echo 'eval "$(starship init bash)"' | tee -a ~/.bashrc
    source ~/.bashrc
    # remove systemd message in prompt
    starship config container.disabled true
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

echo "Common next steps"
echo "*** change host name:"
echo "sudo hostnamectl set-hostname XXX"
