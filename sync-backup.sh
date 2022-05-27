#!/usr/bin/bash

# Notes:
# This script assumes you created a ~/chuboe-system-backup directory and copied this script to this location
# By maintaining multiple sub-directories (private/public), you can use a different backup strategy for each directory
# Create as many sub directories as you wish - create an array per sub directory

# Instuctions
# 1. fill out each of the arrays (private and public)
# 2. Comment out any path/object that does not apply to this server
# 3. Search on the world ACTION and complete the necessary steps

#### Variables ####

#ACTION
BU_REMOTE_NAME=chuboe-sand-01

PATH_LOCAL_PRIVATE=~/chuboe-system-backup/private
mkdir -p $PATH_LOCAL_PRIVATE
PATH_LOCAL_PUBLIC=~/chuboe-system-backup/public
mkdir -p $PATH_LOCAL_PUBLIC

# Create home directories to keep general purpose private files
PATH_GENERAL_PURPOSE_PRIVATE="~/chuboe-keep-private/"
mkdir -p $PATH_GENERAL_PURPOSE_PRIVATE

# Create home directories to keep general purpose public files
PATH_GENERAL_PURPOSE_PUBLIC="~/chuboe-keep-public/"
mkdir -p $PATH_GENERAL_PURPOSE_PUBLIC

#ACTION
RSYNC_BU_USER=SomeUser
RSYNC_BU_URL=some.url.com
RSYNC_BU_PATH=$BU_REMOTE_NAME/backup

#ACTION
AWS_BU_BUCKET_PATH=s3://bucketName/some/path/
# AWS Note - assumes you have already performed:
#   sudo apt install awscli
#   aws --configure

#### Private Array ####
declare -A BU_PRIVATE
BU_PRIVATE[buku]="~/.local/share/buku/"
BU_PRIVATE[jrnl]="~/.local/share/jrnl/"
BU_PRIVATE[jrnl-config]="~/.config/jrnl/"
BU_PRIVATE[id-all]="/opt/idempiere-server/"
BU_PRIVATE[id-log]="/opt/idempiere-server/log/"
BU_PRIVATE[id-utils]="/opt/idempiere-server/utils/"
BU_PRIVATE[sql]="~/sql/"
BU_PRIVATE[keep-private]="$PATH_GENERAL_PURPOSE_PRIVATE"
BU_PRIVATE[sql]="~/sql/"
BU_PRIVATE[chuboe-utils]="/opt/chuboe/idempiere-installation-script/utils/"
BU_PRIVATE[chuboe-backup-archive]="/opt/chuboe/idempiere-installation-script/chuboe_backup/archive/"
BU_PRIVATE[chuboe-backup-latest]="/opt/chuboe/idempiere-installation-script/chuboe_backup/latest/"

#### Public Array ####
declare -A BU_PUBLIC
BU_PUBLIC[keep-public]="$PATH_GENERAL_PURPOSE_PUBLIC"

# example - deleteme
LNS_SOURCE=
LNS_TARGET="$PATH_LOCAL_PRIVATE/buku"
if [ ! -L "$LNS_TARGET" ]; then
    ln -s ~/.local/share/buku/ $PATH_LOCAL_PRIVATE/buku
fi

#### backup private rsync ####

for key in "${!BU_PRIVATE[@]}"; do
    echo "$key ${BU_PRIVATE[$key]}"
	LNS_SOURCE=${BU_PRIVATE[$key]}
	LNS_TARGET="$PATH_LOCAL_PRIVATE/$key"
	if [ ! -L "$LNS_TARGET" ]; then
		ln -s $LNS_SOURCE $LNS_TARGET
	fi
done

exit 0

ssh $RSYNC_BU_USER@$RSYNC_BU_URL mkdir -p $RSYNC_BU_PATH
rsync -rptgoDL $PATH_LOCAL_PRIVATE/ $RSYNC_BU_USER@$RSYNC_BU_URL:$RSYNC_BU_PATH

#Note: if you need to use a pem, things get more interesting with rsync in a script. Here is an example. You need to use the 'eval' command to get the quotations to work
#SC_SSH_PEM_RSYNC="-e \"ssh $SC_SSH_PEM\""
#eval sudo rsync " -P $SC_SSH_PEM_RSYNC -a --delete /some/local/dir/ $RSYNC_BU_USER@$RSYNC_BU_URL:/$RSYNC_BU_PATH"

#### backup private aws ####
aws s3 sync $PATH_LOCAL_PRIVATE/ $AWS_BU_BUCKET_PATH

#### backup public aws ####

for key in "${!BU_PUBLIC[@]}"; do
    echo "$key ${BU_PUBLIC[$key]}"
done

aws s3 sync $PATH_LOCAL_PUBLIC/ $AWS_BU_BUCKET_PATH
