#!/bin/sh

USER_ID=${LRR_UID}
GROUP_ID=${LRR_GID}

echo "Starting LANraragi with UID/GID : $USER_ID/$GROUP_ID"

#Update the koyomi user, using the specified uid/gid. 
#This solves permission problems on the content folder if the Docker user sets the same uid as the owner of the folder.
usermod -u $USER_ID koyomi
groupmod -g $GROUP_ID koyomi

#Ensure LRR folder is writable
chown koyomi /home/koyomi/lanraragi
chmod 744 /home/koyomi/lanraragi

#Crash with an error if content folder doesn't exist
if [ ! -d "/home/koyomi/lanraragi/content" ]; then
  echo "Content folder doesn't exist! Please ensure your Docker mappings are correct."
  exit 1
fi

#Ensure database is writable
chown koyomi /home/koyomi/lanraragi/content/database.rdb
chmod +rw /home/koyomi/lanraragi/content/database.rdb

#Ensure thumbnail folder is writable
chown -R koyomi /home/koyomi/lanraragi/content/thumb 
chmod 744 /home/koyomi/lanraragi/content/thumb

export HOME=/home/koyomi

#Start supervisor with the Docker configuration
#This also loads the redis config to write DB in content directory and disable daemonization
if [ $USER_ID -eq 0 ] && [ $GROUP_ID -eq 0 ] 
then
    echo "UID and GID set to 0, running as root. You've been warned!"
    exec supervisord --nodaemon --configuration ./tools/DockerSetup/supervisord.conf
else   
    exec su-exec koyomi supervisord --nodaemon --configuration ./tools/DockerSetup/supervisord.conf
fi