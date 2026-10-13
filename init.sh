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
SC_BACKUP_SCRIPT_DIR=/opt/chuboe-system-backup

#validations
echo HERE validations
sudo ls &>/dev/null || graceful_exit "user does not have sudo capabilities"

# cwd must be the clone directory for the relative paths below
# (bin-rust/*, alias_nu.txt, .psqlrc, .inputrc, starship.toml, ...).
cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH"

echo HERE apt install
sudo apt update
sudo apt install -y man git git-lfs tree tmux fd-find wget sysstat curl ufw rsync zip pkg-config gcc cmake libssl-dev pipx gpg jc openssh-server fzf ripgrep cron jq moreutils dict screen xdg-utils shellcheck

# jc - JSON Convert - converts the output of many CLI tools, file-types, and common strings for easier parsing in scripts.
# gcc cmake libssl-dev - added for rust toolchain
# pip for python development/tools
# dict - dictionary and thesaurus (install dictd dict-gcide dict-wn if need local results)
# moreutils = vipe + ... (https://joeyh.name/code/moreutils/)
# install shellcheck (https://www.shellcheck.net) -- static analysis for shell scripts

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
    #sudo cp bin-rust/* /usr/local/bin/.
    # Loop through each file in the source directory and create a symbolic link
    for file in bin-rust/*; do
        # Skip if it's a directory
        if [ -f "$file" ]; then
            # Get just the filename without the path
            filename=$(basename "$file")

            # Create the symbolic link
            #sudo ln -s "$(realpath "$file")" "/usr/local/bin/$filename"
            sudo cp "$(realpath "$file")" "/usr/local/bin/$filename"

            #echo "Created symlink for $filename"
        fi
    done


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
    #starship config container.disabled true
    cat ./starship.toml | tee $HOME/.config/starship.toml

    ### add starship to nu
    ##starship init nu | tee -a ~/.cache/starship/init.nu
    ##echo "use ~/.cache/starship/init.nu" | tee -a ~/.config/nushell/config.nu

    zellij setup --generate-completion bash | tee .zellijrc
    echo source $SC_SCRIPTPATH/.zellijrc >> $HOME/.bashrc

    cd /tmp
    echok HERE nerd-fonts
    git clone https://github.com/cboecking/nerd-fonts-installer --depth 1
    cd nerd-fonts-installer
    ./install.sh
    cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH" #this is the location where clone occurred - this is the assumed location moving forward

    #install neovim latest
    echo HERE neovim
    sudo apt install -y ninja-build gettext cmake unzip curl git # neovim dependencies

    # Install tree-sitter CLI (required by upstream kickstart.nvim's auto-parser install).
    # Latest releases (>=0.26.x) require GLIBC 2.39 (Debian trixie); Debian bookworm
    # ships GLIBC 2.36, so we pin to the last release that still builds against 2.36.
    # Bump when trixie becomes the base image.
    TS_VERSION="0.25.10"
    TS_BIN="/usr/local/bin/tree-sitter"
    if ! command -v tree-sitter >/dev/null 2>&1 || ! tree-sitter --version >/dev/null 2>&1; then
        echo "Installing tree-sitter CLI v${TS_VERSION} to ${TS_BIN}..."
        curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VERSION}/tree-sitter-linux-x64.gz" \
            | gunzip > /tmp/tree-sitter
        chmod +x /tmp/tree-sitter
        sudo mv /tmp/tree-sitter "$TS_BIN"
        tree-sitter --version
    fi

    # Persistent neovim source so reruns fast-update instead of re-cloning.
    NEOVIM_SRC="$HOME/.local/src/neovim"
    mkdir -p "$(dirname "$NEOVIM_SRC")"
    if [ -d "$NEOVIM_SRC/.git" ]; then
        git -C "$NEOVIM_SRC" fetch --tags --prune origin
        git -C "$NEOVIM_SRC" checkout stable
        git -C "$NEOVIM_SRC" reset --hard origin/stable
    else
        git clone https://github.com/neovim/neovim "$NEOVIM_SRC"
        git -C "$NEOVIM_SRC" checkout stable
    fi
    cd "$NEOVIM_SRC" || graceful_exit "could not cd to $NEOVIM_SRC"
    # Drop the previous build dir so a toolchain change actually rebuilds; incremental
    # cmake otherwise keeps stale caches.
    rm -rf build
    make CMAKE_BUILD_TYPE=Release -j"$(nproc)"
    sudo make install

    if [ ! -d "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/.git" ]; then
        git clone https://github.com/cboecking/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
    fi
    cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH" #this is the location where clone occurred - this is the assumed location moving forward

    # Download and install nvm and nodejs:
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    \. "$HOME/.nvm/nvm.sh"
    nvm install 22
    # Verify the versions:
    #node -v # Should print...
    #nvm current # Should print...
    #npm -v # Should print...
fi

# create and copy over backup artifacts
# The backup install lives in its own idempotent script so it can be run
# outside of init.sh (e.g. to re-deploy after editing sync-backup.sh or
# conf.d/* without re-running the full init.sh). See install-backup.sh
# for details on what it does and how it preserves operator edits.
echo HERE install chuboe backup
sudo bash "$SC_SCRIPTPATH/install-backup.sh"

# nix package manager
echo HERE install nix package manager
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm


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
