FROM archlinux:latest

ENV container=docker

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
      bash \
      ca-certificates \
      curl \
      dbus \
      iproute2 \
      kmod \
      procps-ng \
      shadow \
      sudo \
      systemd \
    && pacman -Scc --noconfirm

STOPSIGNAL SIGRTMIN+3

CMD ["/usr/lib/systemd/systemd"]
