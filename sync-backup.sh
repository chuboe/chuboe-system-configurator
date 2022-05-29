#!/usr/bin/bash


#### Summary ####
# This script exists to make backing up all desktop and server artifacts simple and easy from a single location.

# Notes:
# While this script comes with the github.com/chuboe/chuboe-system-configurator/, it can be used in isolation if needed
# This script assumes (a) the presence of a ~/chuboe-system-backup directory and (b) this script is copied to this location
# By maintaining multiple sub-directories (private/public), you can use a different backup strategy for each directory

# Minimal Instuctions
# 1. Fill out each of the arrays (private and public)
# 2. Comment out any pre-existing path/object that does not apply to your application
# 3. Search on the world ACTION and complete the necessary steps

# Automated execution
# It is expected that you will add this script to a cronjob for automatic execution
# Here is an example:
#   TODO: add example here


#### Variables ####
#ACTION
# Name of the remote backup directory that will be created for this server on your backup device/service
BU_REMOTE_NAME=chuboe-sand-01

# Create a local consolidation point where we will create a collection of symbolic links
PATH_LOCAL_PRIVATE="private"
mkdir -p $PATH_LOCAL_PRIVATE
PATH_LOCAL_PUBLIC="public"
mkdir -p $PATH_LOCAL_PUBLIC

#ACTION
# Name the remote rsync service
RSYNC_BU_USER=SomeUser
RSYNC_BU_URL=some.url.com
RSYNC_BU_PATH=$BU_REMOTE_NAME/backup

#ACTION
# Name the remote AWS service
AWS_BU_BUCKET_PATH=s3://bucketName/some/path/
# AWS Note - assumes you have already performed:
#   sudo apt install awscli
#   aws --configure


#### Private Backup Array ####
# Create a link to all locations that need to be copied offsite to a private location.
# Uncomment the lines that apply to this server/desktop
declare -A BU_PRIVATE
#BU_PRIVATE[buku]="~/.local/share/buku/"
#BU_PRIVATE[jrnl]="~/.local/share/jrnl/"
#BU_PRIVATE[jrnl-config]="~/.config/jrnl/"
#BU_PRIVATE[id-all]="/opt/idempiere-server/"
#BU_PRIVATE[id-log]="/opt/idempiere-server/log/"
#BU_PRIVATE[id-utils]="/opt/idempiere-server/utils/"
#BU_PRIVATE[sql]="~/sql/"
#BU_PRIVATE[backup-private]=~/chuboe-backup-private
#BU_PRIVATE[chuboe-utils]="/opt/chuboe/idempiere-installation-script/utils/"
#BU_PRIVATE[chuboe-backup-archive]="/opt/chuboe/idempiere-installation-script/chuboe_backup/archive/"
#BU_PRIVATE[chuboe-backup-latest]="/opt/chuboe/idempiere-installation-script/chuboe_backup/latest/"
#BU_PRIVATE[metabase]="/opt/metabase/"


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
rsync -rptgoDL $PATH_LOCAL_PRIVATE/ $RSYNC_BU_USER@$RSYNC_BU_URL:$RSYNC_BU_PATH

#Note: if you need to use a pem, things get more interesting with rsync in a script. Here is an example. You need to use the 'eval' command to get the quotations to work
#SC_SSH_PEM_RSYNC="-e \"ssh $SC_SSH_PEM\""
#eval sudo rsync " -P $SC_SSH_PEM_RSYNC -a --delete /some/local/dir/ $RSYNC_BU_USER@$RSYNC_BU_URL:/$RSYNC_BU_PATH"


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


#### Backup Public via AWS ####
# uncomment if needed
#aws s3 sync $PATH_LOCAL_PUBLIC/ $AWS_BU_BUCKET_PATH
