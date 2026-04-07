FROM archlinux:latest

ENV container=docker

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
      bash \
      ca-certificates \
      curl \
      dbus \
      git \
      iproute2 \
      kmod \
      procps-ng \
      shadow \
      sudo \
      systemd \
    && pacman -Scc --noconfirm

RUN useradd -m -s /bin/bash tester \
    && printf 'tester ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

STOPSIGNAL SIGRTMIN+3

CMD ["/usr/lib/systemd/systemd"]
