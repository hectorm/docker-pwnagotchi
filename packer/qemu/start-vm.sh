#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "${0:?}")")" && pwd -P)
CACHE_DIR=${XDG_CACHE_HOME:-${HOME:?}/.cache}

ARCH=${1-armhf}
DISK=${SRC_DIR:?}/dist/${ARCH:?}/pwnagotchi.img

RPI_KERNEL_URL='https://raw.githubusercontent.com/raspberrypi/firmware/1.20220308/boot/kernel8.img'
RPI_KERNEL_FILE=${2-${CACHE_DIR:?}/raspberrypi/firmware/1.20220308/boot/kernel8.img}

RPI_DTB_URL='https://raw.githubusercontent.com/raspberrypi/firmware/1.20220308/boot/bcm2710-rpi-3-b.dtb'
RPI_DTB_FILE=${3-${CACHE_DIR:?}/raspberrypi/firmware/1.20220308/boot/bcm2710-rpi-3-b.dtb}

# Download RPI kernel and DTB
[ -e "${RPI_KERNEL_FILE:?}" ] || { mkdir -p "$(dirname "${RPI_KERNEL_FILE:?}")" && curl --proto '=https' --tlsv1.3 -Lo "${RPI_KERNEL_FILE:?}" "${RPI_KERNEL_URL:?}"; }
[ -e "${RPI_DTB_FILE:?}"    ] || { mkdir -p "$(dirname "${RPI_DTB_FILE:?}" )"   && curl --proto '=https' --tlsv1.3 -Lo "${RPI_DTB_FILE:?}"    "${RPI_DTB_URL:?}";    }

# Remove keys from the known_hosts file
ssh-keygen -R '[127.0.0.1]:1122' 2>/dev/null
ssh-keygen -R '[localhost]:1122' 2>/dev/null

# hostfwd helper
hostfwd() { printf ',hostfwd=%s::%s-:%s' "$@"; }

# Launch VM
exec qemu-system-aarch64 \
	-machine raspi3b \
	-kernel "${RPI_KERNEL_FILE:?}" -dtb "${RPI_DTB_FILE:?}" \
	-append "$(printf '%s ' \
		'console=ttyAMA0 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=no rootwait' \
		'systemd.mask=rpi-eeprom-update.service systemd.mask=hciuart.service'
	)" \
	-nographic -serial mon:stdio \
	-device usb-net,netdev=n0 \
	-netdev user,id=n0,ipv4=on,ipv6=off,net=10.3.14.0/24,host=10.3.14.1"$(hostfwd \
		tcp 1122 22 \
	)" \
	-drive file="${DISK:?}",if=sd,format=raw,snapshot=on
