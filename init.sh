#!/bin/bash

function graceful_exit
{
      echo -e "Exiting due to an error occuring at $(TZ=US/Eastern date '+%m/%d/%Y %H:%M:%S EST.')\n" | tee -a $LOG_FILE
      echo -e "Some results before the error may have been logged to $LOG_FILE\n"
      echo -e "Here is the error message: $1\n"
      exit 1
}

echo HERE variables
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
SC_OSUSER=$(id -u -n)
SC_OSUSER_GROUP=$(id -g -n)
SC_BACKUP_SCRIPT_DIR=/opt/chuboe-system-backup
SC_BACKUP_SCRIPT=$SC_BACKUP_SCRIPT_DIR/sync-backup.sh

#validations
echo HERE validations
sudo ls &>/dev/null || graceful_exit "user does not have sudo capabilities"

#create shared location
echo HERE create script directory
sudo mkdir -p $SC_BACKUP_SCRIPT_DIR
#sudo chown $SC_OSUSER:$SC_OSUSER_GROUP $SC_BACKUP_SCRIPT_DIR #should not be needed - should be owned by root
cd $SC_BACKUP_SCRIPT_DIR || graceful_exit "could not cd to $SC_BACKUP_SCRIPT_DIR"
cd $HOME || graceful_exit "could not cd to $HOME"
cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH" #this is the location where clone occurred - this is the assumed location moving forward

echo HERE apt install
sudo apt update
sudo apt install -y man git git-lfs tree tmux fd-find wget sysstat curl ufw rsync zip pkg-config gcc cmake libssl-dev pipx gpg jc openssh-server fzf ripgrep cron

# jc - JSON Convert - converts the output of many CLI tools, file-types, and common strings for easier parsing in scripts.
# gcc cmake libssl-dev - added for rust toolchain
# pip for python development/tools

# if you want to update the below files, add anything to the ./init.sh. Example: ./init.sh REDO

if [[ $1 == "" ]]
then

    ## install tmux plugin manager
    #echo HERE install tmux plugin manager
    #git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm

    # install rust eco system
    echo HERE install rust eco
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"

    # copy over bin
    sudo cp bin-rust/* /usr/local/bin/.

    # create nushell aliases
    mkdir -p $HOME/.config/nushell/
    cat alias_nu.txt | tee -a $HOME/.config/nushell/config.nu

    # install jc (python library to convert popular output to json)
    # useful in nushell, example:
    # git log | jc --git-log | from json | take 1 | transpos
    # no longer installed via pip => see apt install above
        # pip install jc

    mkdir -p $HOME/.psql_history.d
    mkdir -p $HOME/.config/
    cp .psqlrc $HOME/.
    cp .inputrc $HOME/.
fi

if [[ $1 == "recompile" ]]
then

    # install nushell
    echo HERE install nushell
    #cargo install nu --locked
    cp $HOME/.cargo/bin/nu ./bin-rust/.

    # install starship prompt
    echo HERE install starship
    #cargo install starship --locked
    cp $HOME/.cargo/bin/starship ./bin-rust/.

    # install zellij (tmux replacement)
    echo HERE install zellij
    #cargo install zellij --locked
    cp $HOME/.cargo/bin/zellij ./bin-rust/.

    # install aichat
    echo HERE install aichat
    #cargo install zellij --locked
    cp $HOME/.cargo/bin/aichat ./bin-rust/.

fi

if [[ $1 == "" ]]
then
    echo HERE update .bashrc
    echo source $SC_SCRIPTPATH/.my_bash >> $HOME/.bashrc
    # starship init => must be last in file
    echo 'eval "$(starship init bash)"' | tee -a $HOME/.bashrc
    source $HOME/.bashrc
    # remove systemd message in prompt
    starship config container.disabled true

    ### add starship to nu
    ##starship init nu | tee -a ~/.cache/starship/init.nu
    ##echo "use ~/.cache/starship/init.nu" | tee -a ~/.config/nushell/config.nu

    zellij setup --generate-completion bash | tee .zellijrc
    echo source $SC_SCRIPTPATH/.zellijrc >> $HOME/.bashrc

    cd /tmp
    echo HERE nerd-fonts
    git clone https://github.com/cboecking/nerd-fonts-installer --depth 1
    cd nerd-fonts-installer
    ./install.sh
    cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH" #this is the location where clone occurred - this is the assumed location moving forward

    #install neovim latest
    cd /tmp
    echo HERE neovim
    sudo apt install -y ninja-build gettext cmake unzip curl git # neovim dependencies
    git clone https://github.com/neovim/neovim
    cd neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=Release
    sudo make install
    git clone https://github.com/cboecking/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
    cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH" #this is the location where clone occurred - this is the assumed location moving forward

fi

# create and copy over backup artifacts
echo HERE copy files
if [[ -f "$SC_BACKUP_SCRIPT" ]]; then
    echo "$SC_BACKUP_SCRIPT exists... skipping..."
else
    sudo cp sync-backup.sh $SC_BACKUP_SCRIPT_DIR/.
    sudo cp chuboe-system-backup-cron $SC_BACKUP_SCRIPT_DIR/.
    sudo cp create-root-ssh-key.sh $SC_BACKUP_SCRIPT_DIR/.
    sudo cp chuboe-system-backup-cron $SC_BACKUP_SCRIPT_DIR/.
    echo "write all system configuration changes here with most recent changes at the top." | sudo tee $SC_BACKUP_SCRIPT_DIR/readme.md
    # Draft a last update version to prevent the first rsync from failing
    sudo touch $SC_BACKUP_SCRIPT_DIR/sync-lastupdate.txt
fi


### system stats ###
# execute this file if you wish the system to automatically collect statistics
# sudo sed -i "s|ENABLED=.*|ENABLED=\"true\"|g" /etc/default/sysstat

# reference: https://www.youtube.com/watch?v=_4WVPSfGqos

# usage after enabled:
# see files: ls -l /var/log/sysstat/
# see statistics for 26th of month: sudo sar -u -f /var/log/sysstat/sa26

echo
echo
echo "Common next steps..."
echo
echo "change host name:"
echo "sudo hostnamectl set-hostname XXX"
echo
echo "system backup instructions:"
echo "cd $SC_BACKUP_SCRIPT_DIR"
echo "cat sync-backup.sh # read instructions at top"
echo
