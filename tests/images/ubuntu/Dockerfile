FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      dbus \
      dbus-user-session \
      iproute2 \
      kmod \
      libpam-systemd \
      procps \
      sudo \
      systemd \
      systemd-sysv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
