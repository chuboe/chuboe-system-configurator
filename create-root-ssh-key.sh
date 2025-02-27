#### RUN as Root ####
SC_OSUSER=$(id -u -n)
echo HERE user=$SC_OSUSER

if [ "$SC_OSUSER" != "root" ]; then
    echo "Error: run script as root. Switch to root using: sudo su"
    exit 1
fi

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
echo NOTE!! Switch to root before executing the below commands: sudo su
echo "****"
echo To upload root key to rsync.net:
echo "RSYNC_BU_USER="
echo "RSYNC_BU_URL="
echo "scp ~/.ssh/id_ed25519.pub \$RSYNC_BU_USER@\$RSYNC_BU_URL:.ssh/authorized_keys"
echo Reference: to upload additional keys to rsync.net:
echo "cat ~/.ssh/id_ed25519.pub | ssh RSYNC_BU_USER@RSYNC_BU_URL 'dd of=.ssh/authorized_keys oflag=append conv=notrunc'"
echo "****"
echo "See for more details: https://erp-academy.chuckboecking.com/?page_id=820"
echo "****"
echo "test using: ssh \$RSYNC_BU_USER@\$RSYNC_BU_URL ls"
echo "****"
