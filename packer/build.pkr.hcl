build {
  sources = [
    "source.arm-image.raspbian"
  ]

  provisioner "file" {
    direction = "upload"
    source = "./rootfs"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "DPKG_FORCE=confold",
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline_shebang = "/bin/sh -eux"
    inline = [
      <<EOF
        find /tmp/rootfs/ -type d -exec chmod 755 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -exec chmod 644 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/\(bin\|cron\..+\)/.+' -exec chmod 755 '{}' ';'
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -fla '{}' / ';'
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
        printf '%s\n' 'deb [arch=armhf] http://http.re4son-kernel.com/re4son/ kali-pi main' > /etc/apt/sources.list.d/re4son.list
        curl --proto '=https' --tlsv1.3 -sSf 'https://re4son-kernel.com/keys/http/archive-key.asc' | apt-key add -
        apt-get update && apt-get install -y \
          kalipi-bootloader \
          kalipi-kernel \
          kalipi-kernel-headers \
          kalipi-re4son-firmware \
          libraspberrypi-bin \
          libraspberrypi-dev \
          libraspberrypi-doc \
          libraspberrypi0
      EOF
      ,
      <<EOF
        printf '%s\n' 'deb [arch=armhf] https://download.docker.com/linux/raspbian/ buster stable' > /etc/apt/sources.list.d/docker.list
        curl --proto '=https' --tlsv1.3 -sSf 'https://download.docker.com/linux/raspbian/gpg' | apt-key add -
        apt-get update && apt-get install -y --no-install-recommends docker-ce
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
        rm -f /etc/ssh/ssh_host*_key*
        rm -rf /var/lib/apt/lists/*
      EOF
    ]
  }
}
