#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"

DOCKER=${DOCKER:-docker} # DOCKER="sudo docker" ./deploy.sh

IMAGE=${IMAGE:-gitolite_image}
CONTAINER=${CONTAINER:-gitolite}

# Settings
if [ ! -f deploy/env.sh ]; then
  cat > deploy/env.sh <<EOF
export APPUSER=git
export APPGROUP=git
export APP_USERDIR=/home/git
export APP_UID=$UID
export APP_GID=$GROUPS
export GIT_CONFIG_KEYS=.*
EOF
fi


if [ -f deploy/.prepare_done ]; then
  rm deploy/.prepare_done
fi

echo "Checking .create.sh ..."
cat > .create.sh.repo <<EOF
#!/bin/bash
P=$(pwd)
IMAGE=${IMAGE}
CONTAINER=${CONTAINER}
ALLOW_STOP=1 # Use Web UI or allow "docker stop <container>"

SSHPORT=\${SSHPORT:-22}
GITPORT=\${GITPORT:-9418}

# gitolite is git submodule, so .git is not available
(cd gitolite; git describe --tags --long --dirty=-dt 2>/dev/null > ../deploy/VERSION)

OPTS="\$DOCKER_OPTS --name \${CONTAINER}"

[[ -z \$CONTAINER_HOSTNAME ]] || OPTS="\$OPTS --hostname \$CONTAINER_HOSTNAME"

[ ! -f deploy/.prepare_done ] || rm deploy/.prepare_done

create_container() {
  docker create -it \\
    \$OPTS \\
    -p \$SSHPORT:22 \\
    -p \$GITPORT:9418 \\
    -v \${P}/deploy:/deploy \\
    -v \${P}/gitolite:/home/git/gitolite \\
    -v \${P}/repositories:/home/git/repositories \\
    -v \${P}/gitolite-logs/:/home/git/.gitolite/logs \\
    -v \${P}/ssh-etc:/etc/ssh \\
    -v \${P}/ssh-git:/home/git/.ssh \\
    \${IMAGE}
}
EOF
if [ -f .create.sh.repo.lastrun ]; then
  diff .create.sh.repo.lastrun .create.sh.repo 1>/dev/null || {
    tput bold 2>/dev/null
    echo "!!!"
    echo "!!! WARNING: Changes were applied into REPOSITORY:"
    echo "!!!"
    tput sgr0 2>/dev/null
    git diff --no-index --color=always -b .create.sh.repo.lastrun .create.sh.repo | tee || true
    tput bold 2>/dev/null
    echo "!!!"
    echo "!!! ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    echo "!!! WARNING: Check and update your .create.sh"
    echo "!!!"
    tput sgr0 2>/dev/null
    echo ""
  }
  if [[ -f .create.sh.repo.lastrun && -f .create.sh.lastrun ]]; then
    if diff .create.sh.repo.lastrun .create.sh.lastrun 1>/dev/null; then
      echo "There is no LOCAL patches"
    else
      tput bold 2>/dev/null
      echo "!!! LOCAL patches are below:"
      tput sgr0 2>/dev/null
      git diff --no-index --color=always -b .create.sh.repo.lastrun .create.sh.lastrun | tee || true
      echo ""
      echo ""
    fi
  fi
fi
if [ ! -f .create.sh ]; then
  echo "Replacing .create.sh"
  cp .create.sh.repo .create.sh
else
  if diff .create.sh.repo .create.sh 1>/dev/null; then
    echo "There is no diff between REPO and LOCAL .create.sh"
  else
    tput bold 2>/dev/null
    echo "Skip replacing of existed .create.sh, current diff:"
    tput sgr0 2>/dev/null
    git diff --no-index --color=always -b .create.sh.repo .create.sh | tee || true
    echo ""
  fi
fi

# Docker image
echo "Build docker image ..."
$DOCKER build -t ${IMAGE} deploy/production


cat <<EOF
================================
1) Check settings in deploy/env.sh
2) Check .create.sh and run ./update_container.sh
EOF
