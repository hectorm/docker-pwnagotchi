#!/bin/sh

# Based on:
# https://github.com/evilsocket/pwnagotchi/blob/master/scripts/linux_connection_share.sh

set -eu

# Name of the ethernet gadget interface on the host
USB_IFACE=${1:-enp0s20u2}
USB_IFACE_IP=10.3.14.1
USB_IFACE_NET=10.3.14.0/24
# Host interface to use for upstream connection
UPSTREAM_IFACE=${2:-enp2s0}

ip addr add "${USB_IFACE_IP:?}/24" dev "${USB_IFACE:?}"
ip link set "${USB_IFACE:?}" up

iptables -A FORWARD -o "${UPSTREAM_IFACE:?}" -i "${USB_IFACE:?}" -s "${USB_IFACE_NET:?}" -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o "${UPSTREAM_IFACE:?}" -j MASQUERADE

printf 1 > /proc/sys/net/ipv4/ip_forward
