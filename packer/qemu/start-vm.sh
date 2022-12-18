#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "${0:?}")")" && pwd -P)
TMP_DIR=$(mktemp -d)

ARCH=${1-armhf}
ORIGINAL_DISK=${SRC_DIR:?}/dist/${ARCH:?}/pwnagotchi.img
SNAPSHOT_DISK=${TMP_DIR:?}/snapshot.qcow2

# Remove temporary files on exit
# shellcheck disable=SC2154
trap 'ret="$?"; rm -rf -- "${TMP_DIR:?}"; trap - EXIT; exit "${ret:?}"' EXIT TERM INT HUP

# Mount boot partition
mkdir "${TMP_DIR:?}"/boot/
guestmount --ro --format=raw --add "${ORIGINAL_DISK:?}" --mount /dev/sda1:/ --pid-file "${TMP_DIR:?}"/guestmount.pid "${TMP_DIR:?}"/boot/
GUESTMOUNT_PID=$(cat "${TMP_DIR:?}"/guestmount.pid)

# Copy kernel and dtb files
cp "${TMP_DIR:?}"/boot/kernel8.img "${TMP_DIR:?}"/kernel.img
cp "${TMP_DIR:?}"/boot/bcm2710-rpi-3-b.dtb "${TMP_DIR:?}"/rpi.dtb

# Unmount boot partition
guestunmount "${TMP_DIR:?}"/boot/
while kill -0 "${GUESTMOUNT_PID:?}" 2>/dev/null; do sleep 1; done

# Create a snapshot image to preserve the original image
qemu-img create -f qcow2 -b "${ORIGINAL_DISK:?}" -F raw "${SNAPSHOT_DISK:?}"
qemu-img resize "${SNAPSHOT_DISK:?}" 8G

# Remove keys from the known_hosts file
ssh-keygen -R '[127.0.0.1]:1122' 2>/dev/null
ssh-keygen -R '[localhost]:1122' 2>/dev/null

# hostfwd helper
hostfwd() { printf ',hostfwd=%s::%s-:%s' "$@"; }

# Launch VM
qemu-system-aarch64 \
	-machine raspi3b \
	-kernel "${TMP_DIR:?}"/kernel.img -dtb "${TMP_DIR:?}"/rpi.dtb \
	-append "$(printf '%s ' \
		'console=ttyAMA0 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=no rootwait' \
		'systemd.mask=rpi-eeprom-update.service systemd.mask=hciuart.service'
	)" \
	-nographic -serial mon:stdio \
	-device usb-net,netdev=n0 \
	-netdev user,id=n0,ipv4=on,ipv6=off,net=10.3.14.0/24,host=10.3.14.1"$(hostfwd \
		tcp 1122 22 \
	)" \
	-drive file="${SNAPSHOT_DISK:?}",if=sd,format=qcow2
