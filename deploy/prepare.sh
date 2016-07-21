#!/bin/bash -e

. /deploy/profile.sh

cp -r /etc/skel/. ${HOME}

if [ ! -f ~/.ssh/id_rsa ]; then
  echo "Missing SSH client keys. Generating..."
  ssh-keygen -q -N '' -C git@server -f ~/.ssh/id_rsa
fi

if [ ! -f ~/.ssh/config ]; then
  cat > ${HOME}/.ssh/config <<EOF
Host *
    StrictHostKeyChecking No
    IdentityFile ${HOME}/.ssh/id_rsa
EOF
  chmod 644 ${HOME}/.ssh/config
fi

mkdir -p $HOME/bin
execute gitolite/install -ln
cp /deploy/VERSION ./gitolite/src/VERSION

update_config() {
  [ ! -f .gitolite.rc ] || {
    [ -f .gitolite.rc.bak ] || cp .gitolite.rc .gitolite.rc.bak
    sed -i "s/^1;$/\$RC{PRE_GIT} = ['gl-pre-git'];\$RC{GIT_CONFIG_KEYS} = '${GIT_CONFIG_KEYS}';\$RC{LOCAL_CODE} = \"\$rc{GL_ADMIN_BASE}\/local\";1;/" .gitolite.rc
    diff -u .gitolite.rc.bak .gitolite.rc || true
  }
}
update_config

if [ ! -d ~/.gitolite/hooks ]; then
  if [ ! -f ~/.ssh/admin.pub ]; then
    if [[ ! -z $GITOLITE_ADMIN_KEY ]]; then
      echo "$GITOLITE_ADMIN_KEY" > /.ssh/admin.pub
    else
      if [[ ! -d ~/repositories/gitolite-admin.git ]]; then
        echo "Using admin key from repositories/gitolite-admin.git"
        (cd ~/repositories/gitolite-admin.git; git show HEAD:keydir/admin.pub > /.ssh/admin.pub)
      fi
    fi

    if [ ! -f ~/.ssh/admin.pub ]; then
      echo "FATAL: Missing admin public key. Put it into ssh-git/admin.pub or specify via environment GITOLITE_ADMIN_KEY"
      exit 1
    fi
  fi

  if [ -d ./repositories/gitolite-admin.git ]; then
    # Bootstrap from an existing gitolite-admin
    execute mv ./repositories/gitolite-admin.git{,-tmp}
    execute bin/gitolite setup -pk ~/.ssh/admin.pub
    update_config
    execute rm -rf ./repositories/gitolite-admin.git
    execute mv ./repositories/gitolite-admin.git{-tmp,}
    (
      cd /home/git/repositories/gitolite-admin.git
      GL_LIBDIR=$(/home/git/bin/gitolite query-rc GL_LIBDIR) PATH=$PATH:/home/git/bin \
        ~/.gitolite/hooks/gitolite-admin/post-update refs/heads/master
    )
  else
    execute bin/gitolite setup -pk ~/.ssh/admin.pub
    update_config
  fi
else
  execute bin/gitolite setup
fi
