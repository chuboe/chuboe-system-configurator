#!/usr/bin/bash

# Notes:
# This script assumes you created a ~/chuboe-system-backup directory and copied this script to this location
# By maintaining multiple sub-directories (private/public), you can use a different backup strategy for each directory.

# Instuctions
# 1. Keep the creation of all symbolic links in this script. Do not create them manually.
#    It is ok to re-create them every time.
#    The actual sync statements are at the bottom of this script
# 2. Search on ACTION and update accordingly

#### Variables ####

#ACTION
REMOTE_NAME_THIS_COMPUTER=Chuboe-Sand-01

PATH_LOCAL_PRIVATE=~/chuboe-system-backup/private
PATH_LOCAL_PUBLIC=~/chuboe-system-backup/public

#ACTION
RSYNC_BU_USER=SomeUser
RSYNC_BU_URL=some.url.com
RSYNC_BU_PATH=$REMOTE_NAME_THIS_COMPUTER/backup

#ACTION
AWS_BU_BUCKET_PATH=s3://bucketName/some/path/
# AWS Note - assumes you have already performed:
#   sudo apt install awscli
#   aws --configure

# Create as many folders as you need. Each folder can have a different strategy
mkdir -p $PATH_LOCAL_PRIVATE
mkdir -p $PATH_LOCAL_PUBLIC

#### list of items to be backed up ####

#buku - bookmarks
ln -s ~/.local/share/buku/ $PATH_LOCAL_PRIVATE/buku

#jrnl - journal
ln -s ~/.local/share/jrnl/ $PATH_LOCAL_PRIVATE/jrnl
ln -s ~/.config/jrnl/ $PATH_LOCAL_PRIVATE/jrnl-config

#id-all
ln -s /opt/idempiere-server/ $PATH_LOCAL_PRIVATE/idempiere

#id-log
ln -s /opt/idempiere-server/log/ $PATH_LOCAL_PRIVATE/idempiere-log

#id-utils
ln -s /opt/idempiere-server/utils/ $PATH_LOCAL_PRIVATE/idempiere-utils

#sql
ln -s ~/sql/ $PATH_LOCAL_PRIVATE/sql

#keep-private
mkdir -p ~/chuboe-keep-private/
ln -s ~/chuboe-keep-private/ $PATH_LOCAL_PRIVATE/keep-private

#keep-publish - note: public
mkdir -p ~/chuboe-keep-publish/
ln -s ~/chuboe-keep-publish/ $PATH_LOCAL_PUBLIC/keep-publish

#chuboe-utils
ln -s /opt/chuboe/idempiere-installation-script/utils/ $PATH_LOCAL_PRIVATE/chuboe-utils

#chuboe-backup-archive
ln -s /opt/chuboe/idempiere-installation-script/chuboe_backup/archive/ $PATH_LOCAL_PRIVATE/chuboe-backup-archive

#chuboe-backup-latest
ln -s /opt/chuboe/idempiere-installation-script/chuboe_backup/latest/ $PATH_LOCAL_PRIVATE/chuboe-backup-latest

#### backup private rsync ####
rsync -rptgoDL $PATH_LOCAL_PRIVATE/ $RSYNC_BU_USER@$RSYNC_BU_URL:$RSYNC_BU_PATH

#Note: if you need to use a pem, things get more interesting with rsync in a script. Here is an example. You need to use the 'eval' command to get the quotations to work
#SC_SSH_PEM_RSYNC="-e \"ssh $SC_SSH_PEM\""
#eval sudo rsync " -P $SC_SSH_PEM_RSYNC -a --delete /some/local/dir/ $RSYNC_BU_USER@$RSYNC_BU_URL:/$RSYNC_BU_PATH"

#### backup private aws ####
aws s3 sync $PATH_LOCAL_PRIVATE/ $AWS_BU_BUCKET_PATH

#### backup public aws ####
aws s3 sync $PATH_LOCAL_PUBLIC/ $AWS_BU_BUCKET_PATH
