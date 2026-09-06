FROM fedora:43

# systemd runs as PID 1 so the roles can manage zookeeper.service and
# patroni.service exactly as they do on a VM. Everything else here is
# only what Ansible needs before the common role takes over:
# python3-libdnf5 for the dnf backend, procps-ng/iproute/hostname for
# the modules that shell out.
RUN dnf -y install --setopt=install_weak_deps=False \
      systemd \
      python3 \
      python3-libdnf5 \
      procps-ng \
      iproute \
      hostname \
      sudo \
      passwd \
  && dnf clean all \
  && rm -rf /var/cache/dnf

# Units that need real hardware or a host udev; they fail and drag
# multi-user.target down with them inside a container.
RUN systemctl mask \
      dev-hugepages.mount \
      sys-fs-fuse-connections.mount \
      systemd-remount-fs.service \
      systemd-udevd.service \
      systemd-udev-trigger.service \
      console-getty.service \
      getty.target

# SIGRTMIN+3 is systemd's shutdown signal; SIGTERM only reboots it, so
# without this `docker compose down` waits out the timeout and kills it.
STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
