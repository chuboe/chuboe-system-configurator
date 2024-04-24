#!/bin/bash
# this script will disable gpg (password-store) cache and force the user to enter passphrase after locking the screen
# to use this, copy the gpg-timeout.desktop file to ~/.config/autostart/gpg-timeout.desktop
#   doing so will auto execute the below script
while read x
do
    case "$x" in
        *"boolean true"*) echo RELOADAGENT | gpg-connect-agent;;
    esac
done < <(dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'")
