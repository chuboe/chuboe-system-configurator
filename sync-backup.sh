#!/bin/bash

#### Summary ####
# This script exists to make backing up all desktop and server artifacts simple and easy from a single location.

# Notes:
# While this script comes with the github.com/chuboe/chuboe-system-configurator/, it can be used in isolation if needed
# This script assumes (a) the presence of a /opt/chuboe-system-backup directory and (b) this script is copied to this location
# By maintaining multiple sub-directories (private/public), you can use a different backup strategy for each directory

# Minimal Instuctions
# 1. Fill out each of the arrays (private [BU_PRIVATE] and public [BU_PUBLIC])
# 2. Un-comment any pre-existing paths/objects that apply to your application
# 3. Search on the world ACTION and complete the necessary steps

# Automated execution
# It is expected that you will add this script to a cronjob for automatic execution
# Here is an example:
#   TODO: add example here

function graceful_exit
{
      echo -e "Exiting due to an error occuring at $(TZ=US/Eastern date '+%m/%d/%Y %H:%M:%S EST.')\n" | tee -a $LOG_FILE
      echo -e "Some results before the error may have been logged to $LOG_FILE\n"
      echo -e "Here is the error message: $1\n"
      exit 1
}

#### Variables ####
echo HERE variables
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
SC_OSUSER=$(id -u -n)
SC_OSUSER_GROUP=$(id -g -n)
cd $SC_SCRIPTPATH || graceful_exit "could not cd to $SC_SCRIPTPATH"


#ACTION
# Name of the remote backup directory that will be created for this server on your backup device/service
BU_REMOTE_NAME=chuboe-sand-01
# Some of the below backup sources belong to one or more users - this is the primary non-root user
USER_PRIMARY=debian
USER_HOME=/home/$USER_PRIMARY

# Create a local consolidation point where we will create a collection of symbolic links
PATH_LOCAL_PRIVATE="private"
mkdir -p $PATH_LOCAL_PRIVATE
PATH_LOCAL_PUBLIC="public"
mkdir -p $PATH_LOCAL_PUBLIC

#ACTION
# Name the remote rsync service
RSYNC_BU_USER=SomeRsyncUser
RSYNC_BU_URL=SomeRsyncUser.rsync.net
RSYNC_BU_PATH=$BU_REMOTE_NAME/backup

#ACTION if using aws for backup - not recommended
# Name the remote AWS service
#AWS_BU_BUCKET_PATH=s3://bucketName/some/path/
# AWS Note - assumes you have already performed:
#   sudo apt install awscli
#   aws --configure


#### Private Backup Array ####
# Create a link to all locations that need to be copied offsite to a private location.
# Uncomment the lines that apply to this server/desktop
declare -A BU_PRIVATE
#BU_PRIVATE[gpg]=$USER_HOME/.gnupg
#BU_PRIVATE[password-store]=$USER_HOME/.password-store
#BU_PRIVATE[Passwords.kdbx]=$USER_HOME/Passwords.kdbx
#BU_PRIVATE[buku]=$USER_HOME/.local/share/buku/
#BU_PRIVATE[jrnl]=$USER_HOME/.local/share/jrnl/
#BU_PRIVATE[jrnl-config]=$USER_HOME/.config/jrnl/
#BU_PRIVATE[aichat-config]=$USER_HOME/.config/aichat/
#BU_PRIVATE[all-config]=$USER_HOME/.config/ #note this does not always work depending on embedded symlinks
#BU_PRIVATE[bash-history]=$USER_HOME/.bash_history
#BU_PRIVATE[bash-history-root]=$HOME/.bash_history
#BU_PRIVATE[ssh]=$USER_HOME/.ssh/
#BU_PRIVATE[ssh-root]=$HOME/.ssh/
#BU_PRIVATE[aws]=$USER_HOME/.aws/
#BU_PRIVATE[id-all]="/opt/idempiere-server/"
#BU_PRIVATE[id-log]="/opt/idempiere-server/log/"
#BU_PRIVATE[id-utils]="/opt/idempiere-server/utils/"
#BU_PRIVATE[id-attach]="/opt/idempiere-attach/"
#BU_PRIVATE[id-archive]="/opt/idempiere-archive/"
#BU_PRIVATE[id-image]="/opt/idempiere-image/"
#BU_PRIVATE[id-dms-content]="/opt/DMS_Content/"
#BU_PRIVATE[id-dms-thumbnail]="/opt/DMS_Thumbnails/"
#BU_PRIVATE[backup-private]=$USER_HOME/chuboe-backup-private
#BU_PRIVATE[chuboe-utils]="/opt/chuboe/idempiere-installation-script/utils/"
#BU_PRIVATE[chuboe-id-backup-archive]="/opt/chuboe/idempiere-installation-script/chuboe_backup/archive/"
#BU_PRIVATE[chuboe-id-backup-latest]="/opt/chuboe/idempiere-installation-script/chuboe_backup/latest/"
#BU_PRIVATE[metabase]="/opt/metabase/"
#BU_PRIVATE[metabase-code]=$USER_HOME/code/metabase/
#BU_PRIVATE[sql]=$USER_HOME/sql/
#BU_PRIVATE[postgres-config]="/etc/postgresql/17/main/"
#BU_PRIVATE[postgres-history]=$USER_HOME/.psql_history.d/
#BU_PRIVATE[postgres-log-start]=/var/log/postgresql/
#BU_PRIVATE[postgres-log-query]=/var/lib/postgresql/17/main/log/
#BU_PRIVATE[incus-export]=$USER_HOME/incus-export/
#BU_PRIVATE[tmux-save]=$USER_HOME/.tmux-save/
#BU_PRIVATE[cron-d]=/etc/cron.d/
#BU_PRIVATE[crontab]=/etc/crontab
#BU_PRIVATE[os-release]=/etc/os-release
#BU_PRIVATE[haproxy.cfg]=/etc/haproxy/haproxy.cfg
#BU_PRIVATE[apache-config]=/etc/apache2/
#BU_PRIVATE[nginx-config]=/etc/nginx/
#BU_PRIVATE[nginx-log]=/var/log/nginx/
#BU_PRIVATE[www]=/var/www/
#BU_PRIVATE[ssl-certs]=/etc/ssl/certs/
BU_PRIVATE[sync-backup.sh]=/opt/chuboe-system-backup/sync-backup.sh
BU_PRIVATE[sync-lastupdate.txt]=/opt/chuboe-system-backup/sync-lastupdate.txt

#### created for convenience ####
#mkdir -p ~/sql/
#mkdir -p ~/chuboe-backup-private-$USER_PRIMARY

#### Public Backup Array ####
# Create a link to all locations that need to be copied offsite to a publicly accessible location.
# Uncomment the lines that apply to this server/desktop
declare -A BU_PUBLIC
#BU_PUBLIC[backup-public]=~/chuboe-backup-public


#### Create Private Links ####
#Create sumbolic link so that a single backup script and push all backup locations as once
for key in "${!BU_PRIVATE[@]}"; do
    echo "$key ${BU_PRIVATE[$key]}"
	LNS_SOURCE=${BU_PRIVATE[$key]}
	LNS_TARGET="$PATH_LOCAL_PRIVATE/$key"
	if [ ! -L "$LNS_TARGET" ]; then
		ln -s $LNS_SOURCE $LNS_TARGET
	fi
done


#### Backup Private via Rsync ####
ssh $RSYNC_BU_USER@$RSYNC_BU_URL mkdir -p $RSYNC_BU_PATH
rsync -rptgoDL --delete $PATH_LOCAL_PRIVATE/ $RSYNC_BU_USER@$RSYNC_BU_URL:$RSYNC_BU_PATH

#Note: if you need to use a pem, things get more interesting with rsync in a script. Here is an example. You need to use the 'eval' command to get the quotations to work
#SC_SSH_PEM_RSYNC="-e \"ssh $SC_SSH_PEM\""
#eval rsync " -P $SC_SSH_PEM_RSYNC -a --delete /some/local/dir/ $RSYNC_BU_USER@$RSYNC_BU_URL:/$RSYNC_BU_PATH"


#### Backup Private via AWS ####
# uncomment if needed
#aws s3 sync $PATH_LOCAL_PRIVATE/ $AWS_BU_BUCKET_PATH


#### Create Public Links ####
for key in "${!BU_PUBLIC[@]}"; do
    echo "$key ${BU_PUBLIC[$key]}"
	LNS_SOURCE=${BU_PUBLIC[$key]}
	LNS_TARGET="$PATH_LOCAL_PUBLIC/$key"
	if [ ! -L "$LNS_TARGET" ]; then
		ln -s $LNS_SOURCE $LNS_TARGET
	fi
done


#### Backup Public via Rsync ####
# TODO

#### Create root ssh-keygen ####
if [[ -f "~/.ssh/id_ed25519" ]]; then
    echo "HERE ed25519 key already exists for root"
else
    echo "HERE creating ed25519 key for root"
    ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -N ""
fi


#### Backup Public via AWS ####
# uncomment if needed
#aws s3 sync $PATH_LOCAL_PUBLIC/ $AWS_BU_BUCKET_PATH

#### Help Instructions ####
echo
echo "****"
echo rsync.net help instructions: Allow access to rsync.net without entering a password
echo "****"
echo NOTE!! Switch to root before executing the below commands: sudo su -
echo "****"
echo To upload root key to rsync.net:
echo "scp ~/.ssh/id_ed25519.pub $RSYNC_BU_USER@$RSYNC_BU_URL:.ssh/authorized_keys"
echo Reference: to upload additional keys to rsync.net:
echo "cat ~/.ssh/id_ed25519.pub | ssh $RSYNC_BU_USER@$RSYNC_BU_URL 'dd of=.ssh/authorized_keys oflag=append conv=notrunc'"
echo "****"
echo "See for more details: https://erp-academy.chuckboecking.com/?page_id=820"
echo "****"
