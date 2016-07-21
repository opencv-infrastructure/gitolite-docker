#!/bin/bash -e
# git-daemon access hook
exec 1>>/home/git/.gitolite/logs/git-daemon-access.log
exec 2>&1
echo $*
REPO=`pwd | sed -e "s/\/home\/git\/repositories\///" | sed -e "s/.git\$//"`
echo "repo: $REPO"
ERR=`/home/git/bin/gitolite access $REPO daemon R $1` || (echo "    ERROR: Access denied: $ERR"; exit 1)
/home/git/bin/gitolite trigger PRE_GIT $REPO daemon R $1 && echo "  OK" || (echo "    ERROR: FAIL"; exit 1)
exit 0
