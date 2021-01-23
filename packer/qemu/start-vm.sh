#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "${0:?}")" && pwd -P)
TMP_DIR=$(mktemp -d)

ARCH=${1-armhf}
ORIGINAL_DISK=${SRC_DIR:?}/dist/${ARCH:?}/pwnagotchi.img
SNAPSHOT_DISK=${TMP_DIR:?}/snapshot.qcow2

RPI_KERNEL_URL='https://raw.githubusercontent.com/raspberrypi/firmware/stable/boot/kernel8.img'
RPI_KERNEL_FILE=${2-${TMP_DIR:?}/kernel.img}

RPI_DTB_URL='https://raw.githubusercontent.com/raspberrypi/firmware/stable/boot/bcm2710-rpi-3-b.dtb'
RPI_DTB_FILE=${3-${TMP_DIR:?}/rpi.dtb}

# Remove temporary files on exit
# shellcheck disable=SC2154
trap 'ret="$?"; rm -rf -- "${TMP_DIR:?}"; trap - EXIT; exit "${ret:?}"' EXIT TERM INT HUP

# Create a snapshot image to preserve the original image
qemu-img create -b "${ORIGINAL_DISK:?}" -f qcow2 "${SNAPSHOT_DISK:?}"
qemu-img resize "${SNAPSHOT_DISK:?}" +2G

# Download RPI kernel and DTB
[ -e "${RPI_KERNEL_FILE:?}" ] || curl --proto '=https' --tlsv1.2 -Lo "${RPI_KERNEL_FILE:?}" "${RPI_KERNEL_URL:?}"
[ -e "${RPI_DTB_FILE:?}"    ] || curl --proto '=https' --tlsv1.2 -Lo "${RPI_DTB_FILE:?}"    "${RPI_DTB_URL:?}"

# Launch VM
qemu-system-aarch64 \
	-nographic -serial mon:stdio \
	-machine raspi3 -m 1024 \
	-kernel "${RPI_KERNEL_FILE:?}" -dtb "${RPI_DTB_FILE:?}" \
	-append 'console=ttyAMA0 root=/dev/mmcblk0p2 fsck.repair=no rootwait systemd.mask=rpi-eeprom-update.service systemd.mask=hciuart.service' \
	-drive file="${SNAPSHOT_DISK:?}",if=sd,format=qcow2
