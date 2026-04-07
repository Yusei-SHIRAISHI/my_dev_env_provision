FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      dbus \
      git \
      iproute2 \
      kmod \
      procps \
      sudo \
      systemd \
      systemd-sysv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash tester \
    && printf 'tester ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
