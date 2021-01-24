build {
  sources = [
    "source.arm-image.arm64",
    "source.arm-image.armhf"
  ]

  provisioner "file" {
    direction = "upload"
    source = "./rootfs"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "TZ=UTC",
      "LANG=en_US.UTF-8",
      "LC_ALL=en_US.UTF-8",
      "DPKG_FORCE=confold",
      "DEBIAN_FRONTEND=noninteractive",
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ]
    inline_shebang = "/bin/sh -eux"
    inline = [
      <<EOF
        find /tmp/rootfs/ -type f -name .gitkeep -delete
        find /tmp/rootfs/ -type d -exec chmod 755 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -exec chmod 644 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/\(bin/.+\|rc\.local$\)' -exec chmod 755 '{}' ';'
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -fa '{}' / ';'
        rm -rf /tmp/rootfs/
      EOF
      ,
      <<EOF
        hostname -F /etc/hostname
        rm -f /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata
        dpkg-reconfigure -f noninteractive locales
        dpkg-reconfigure -f noninteractive keyboard-configuration
      EOF
      ,
      <<EOF
        apt-get update
        apt-get dist-upgrade -y
      EOF
      ,
      <<EOF
        apt-mark hold \
          firmware-brcm80211
      EOF
      ,
      <<EOF
        apt-get install -y \
          apt-transport-https \
          ca-certificates \
          crda \
          curl \
          dnsmasq \
          dphys-swapfile \
          gnupg \
          htop \
          i2c-tools \
          openssh-server
      EOF
      ,
      <<EOF
        apt-get purge -y \
          bluez \
          nfs-common \
          raspberrypi-net-mods \
          triggerhappy \
          unattended-upgrades \
          wpasupplicant
        apt-get autoremove -y
      EOF
      ,
      <<EOF
        printf '%s\n' "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/raspbian/ $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        curl --proto '=https' --tlsv1.3 -sSf 'https://download.docker.com/linux/raspbian/gpg' | apt-key add -
        apt-get update && apt-get install -y docker-ce
      EOF
      ,
      <<EOF
        rpi-nexmon-update
      EOF
      ,
      <<EOF
        systemctl disable \
          apt-daily-upgrade.timer \
          apt-daily.timer \
          dhcpcd.service \
          fake-hwclock.service
        systemctl enable \
          dnsmasq.service \
          docker.service \
          dphys-swapfile.service \
          fstrim.timer \
          ssh.service
      EOF
      ,
      <<EOF
        rm -f /etc/ssh/ssh_host_*key*
        find /var/lib/apt/lists/ -mindepth 1 -delete
        find / -type f -regex '.+\.\(dpkg\|ucf\)-\(old\|new\|dist\)' -ignore_readdir_race -delete ||:
      EOF
    ]
  }
}
