#!/bin/bash -e

. /deploy/profile.sh

execute gitolite list-users
execute gitolite list-repos

execute /usr/lib/git-core/git-daemon --reuseaddr \
  --access-hook=/home/git/repositories/access_hook.sh \
  --base-path=/home/git/repositories \
  --export-all \
  --verbose \
  >>/home/git/.gitolite/logs/git-daemon.log 2>&1
echo "ERROR: git-daemon is dead"
exit 1
