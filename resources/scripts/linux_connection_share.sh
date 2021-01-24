#!/bin/sh

set -eu

USB_IFACE=${1:-enp0s20u2}
USB_IFACE_NET=10.3.14.0/24
UPSTREAM_IFACE=${2:-enp2s0}

iptables -A FORWARD -o "${UPSTREAM_IFACE:?}" -i "${USB_IFACE:?}" -s "${USB_IFACE_NET:?}" -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o "${UPSTREAM_IFACE:?}" -j MASQUERADE

printf 1 > /proc/sys/net/ipv4/ip_forward
