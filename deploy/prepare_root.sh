#!/bin/bash -e

id -u $APPUSER 2>/dev/null || {
  echo "Create user/group: $APPUSER:$APPGROUP ($APP_UID:$APP_GID) from ${APP_USERDIR}"
  execute groupadd --system -g $APP_GID $APPGROUP
  execute useradd --system -u $APP_UID -g $APPGROUP -d ${APP_USERDIR} -m -s /bin/bash -c "User" $APPUSER
}

[[ `id -u $APPUSER 2>/dev/null` = ${APP_UID} ]] || {
  echo "FATAL: User already exists with wrong ID";
  exit 1
}

execute chown $APPUSER:$APPGROUP $APP_USERDIR
[[ ! -d $APP_USERDIR/.ssh ]] || {
  set -x
  chown -R $APPUSER:$APPGROUP $APP_USERDIR/.ssh
  chmod 755 $APP_USERDIR/.ssh
  chmod 644 $APP_USERDIR/.ssh/*
  find $APP_USERDIR/.ssh/ \( -name "*rsa" -o -name "*key" \) -exec chmod 600 {} \;
  set +x
}
[[ ! -d /etc/ssh ]] || {
  set -x
  chown -R root:root /etc/ssh
  chmod 755 /etc/ssh
  chmod 644 /etc/ssh/*
  find /etc/ssh/ \( -name "*rsa" -o -name "*key" \) -exec chmod 600 {} \;
  set +x
}
[[ ! -d $APP_USERDIR/repositories ]] || {
  execute chown -R $APPUSER:$APPGROUP $APP_USERDIR/repositories
}
[[ ! -d $APP_USERDIR/.gitolite ]] || {
  execute chown -R $APPUSER:$APPGROUP $APP_USERDIR/.gitolite
}


execute locale-gen en_US.UTF-8
execute dpkg-reconfigure locales

execute dpkg-reconfigure openssh-server

# To avoid annoying "perl: warning: Setting locale failed." errors,
# do not allow the client to pass custom locals, see:
# http://stackoverflow.com/a/2510548/15677
sed -i 's/^AcceptEnv LANG LC_\*$//g' /etc/ssh/sshd_config

# http://stackoverflow.com/questions/22547939/docker-gitlab-container-ssh-git-login-error
#sed -i '/session    required     pam_loginuid.so/d' /etc/pam.d/sshd

# Missing privilege separation directory: /var/run/sshd
#mkdir -p /var/run/sshd
