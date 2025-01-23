#!/bin/bash

function graceful_exit
{
      echo -e "Exiting due to an error occuring at $(TZ=US/Eastern date '+%m/%d/%Y %H:%M:%S EST.')\n" | tee -a $LOG_FILE
      echo -e "Some results before the error may have been logged to $LOG_FILE\n"
      echo -e "Here is the error message: $1\n"
      exit 1
}

SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
cd $SC_SCRIPTPATH || graceful_exit "could not cd to desired path"

sudo apt update
sudo apt install -y man git git-lfs tree tmux fd-find wget sysstat curl ufw rsync zip pkg-config gcc cmake libssl-dev pipx gpg jc openssh-server fzf ripgrep

# jc - JSON Convert - converts the output of many CLI tools, file-types, and common strings for easier parsing in scripts.
# gcc cmake libssl-dev - added for rust toolchain
# pip for python development/tools

# if you want to update the below files, add anything to the ./init.sh. Example: ./init.sh REDO

if [[ $1 == "" ]]
then

    ## install tmux plugin manager
    #echo HERE install tmux plugin manager
    #git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # install rust eco system
    echo HERE install rust eco
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"

    # copy over bin
    cp bin-rust/* ~/.cargo/bin/.

    # create nushell aliases
    mkdir -p ~/.config/nushell/
    cat alias_nu.txt | tee -a ~/.config/nushell/config.nu

    # install jc (python library to convert popular output to json)
    # useful in nushell, example:
    # git log | jc --git-log | from json | take 1 | transpos
    # no longer installed via pip => see apt install above
        # pip install jc

    mkdir -p ~/.psql_history.d
    mkdir -p ~/.config/
    cp .psqlrc ~/.
    cp .inputrc ~/.
fi

if [[ $1 == "recompile" ]]
then

    # install nushell
    echo HERE install nushell
    #cargo install nu --locked
    cp ~/.cargo/bin/nu ./bin-rust/.

    # install starship prompt
    echo HERE install starship
    #cargo install starship --locked
    cp ~/.cargo/bin/starship ./bin-rust/.

    # install zellij (tmux replacement)
    echo HERE install zellij
    #cargo install zellij --locked
    cp ~/.cargo/bin/zellij ./bin-rust/.

fi

if [[ $1 == "" ]]
then
    echo HERE update .bashrc
    echo source \~/chuboe-system-configurator/.my_bash >> ~/.bashrc
    # starship init => must be last in file
    echo 'eval "$(starship init bash)"' | tee -a ~/.bashrc
    source ~/.bashrc
    # remove systemd message in prompt
    starship config container.disabled true

    ### add starship to nu
    ##starship init nu | tee -a ~/.cache/starship/init.nu
    ##echo "use ~/.cache/starship/init.nu" | tee -a ~/.config/nushell/config.nu

    zellij setup --generate-completion bash | tee .zellijrc
    echo source \~/chuboe-system-configurator/.zellijrc >> ~/.bashrc

    cd /tmp
    git clone https://github.com/cboecking/nerd-fonts-installer --depth 1
    cd nerd-fonts-installer
    ./install.sh
    cd $SC_SCRIPTPATH

    #install neovim latest
    cd /tmp
    sudo apt install -y ninja-build gettext cmake unzip curl git # neovim dependencies
    git clone https://github.com/neovim/neovim
    cd neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=Release
    sudo make install
    git clone https://github.com/cboecking/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
    cd $SC_SCRIPTPATH

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
