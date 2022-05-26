#!/bin/bash

# wishlist
# - create symbolic links to .psqlrc and inputrc

sudo apt update
sudo apt install -y vim git tree tmux fd-find wget

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
    echo source \~/chuboe_system_configurator/.my_bash >> ~/.bashrc
fi
