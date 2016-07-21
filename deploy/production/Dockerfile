FROM ubuntu:14.04

RUN \
  apt-get update && \
  apt-get install -y \
    openssh-server git \
    && \
  rm -rf /var/lib/apt/lists/* && \
  rm -f /etc/ssh/ssh_host_*

CMD ["/deploy/entry.sh"]
