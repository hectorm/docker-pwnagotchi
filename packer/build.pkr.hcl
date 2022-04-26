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
    skip_clean = true
    execute_command = "/usr/bin/env -i {{ .Vars }} /bin/sh -eux {{ .Path }}"
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
        apt-get install -y \
          bash \
          ca-certificates \
          crda \
          curl \
          dnsmasq \
          dphys-swapfile \
          gnupg \
          htop \
          i2c-tools \
          jq \
          openssh-server \
          zstd
      EOF
      ,
      <<EOF
        apt-get purge -y \
          bluez \
          firmware-brcm80211 \
          nfs-common \
          raspberrypi-net-mods \
          triggerhappy \
          unattended-upgrades \
          wpasupplicant
        apt-get autoremove -y
      EOF
      ,
      <<EOF
        curl --proto '=https' --tlsv1.3 -sSf 'https://download.docker.com/linux/raspbian/gpg' | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
        printf '%s\n' "deb [arch=armhf signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/raspbian/ $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
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
          pwnagotchi.service \
          ssh.service
      EOF
      ,
      <<EOF
        download-frozen-image /tmp/pwnagotchi-image/ hectorm/pwnagotchi:latest
        tar -cf /var/lib/pwnagotchi-image.tar -C /tmp/pwnagotchi-image/ ./
        rm -rf /tmp/pwnagotchi-image/
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
