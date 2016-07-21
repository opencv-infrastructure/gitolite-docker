#!/bin/bash -e
echo "Starting gitolite container..."

. /deploy/profile.sh

if [ -f /deploy/.prepare_done_ignore ]; then
  echo "Preparation step is already completed. Remove deploy/.prepare_done to run it again"
else
  . /deploy/prepare_root.sh || exit 1
  su - $APPUSER -c /deploy/prepare.sh || exit 1
  su - $APPUSER -c "touch /deploy/.prepare_done"
fi

#execute /usr/sbin/sshd -D
#while true; do sleep 1000; done
execute /etc/init.d/ssh start
su - $APPUSER -c /deploy/launch.sh
echo "Application FAILED"
exit 1
