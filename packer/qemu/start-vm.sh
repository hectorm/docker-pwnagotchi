#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "${0:?}")")" && pwd -P)
TMP_DIR=$(mktemp -d)

ARCH=${1-armhf}
DISK=${SRC_DIR:?}/dist/${ARCH:?}/pwnagotchi.img

RPI_KERNEL_URL='https://raw.githubusercontent.com/raspberrypi/firmware/1.20200601/boot/kernel8.img'
RPI_KERNEL_FILE=${2-${TMP_DIR:?}/kernel.img}

RPI_DTB_URL='https://raw.githubusercontent.com/raspberrypi/firmware/1.20200601/boot/bcm2710-rpi-3-b.dtb'
RPI_DTB_FILE=${3-${TMP_DIR:?}/rpi.dtb}

# Remove temporary files on exit
# shellcheck disable=SC2154
trap 'ret="$?"; rm -rf -- "${TMP_DIR:?}"; trap - EXIT; exit "${ret:?}"' EXIT TERM INT HUP

# Download RPI kernel and DTB
[ -e "${RPI_KERNEL_FILE:?}" ] || curl --proto '=https' --tlsv1.2 -Lo "${RPI_KERNEL_FILE:?}" "${RPI_KERNEL_URL:?}"
[ -e "${RPI_DTB_FILE:?}"    ] || curl --proto '=https' --tlsv1.2 -Lo "${RPI_DTB_FILE:?}"    "${RPI_DTB_URL:?}"

# Launch VM
qemu-system-aarch64 \
	-machine raspi3b -m 1024 \
	-kernel "${RPI_KERNEL_FILE:?}" -dtb "${RPI_DTB_FILE:?}" \
	-append 'console=ttyAMA0 root=/dev/mmcblk0p2 fsck.repair=no rootwait systemd.mask=rpi-eeprom-update.service systemd.mask=hciuart.service' \
	-nographic -serial mon:stdio \
	-drive file="${DISK:?}",if=sd,format=raw,snapshot=on
