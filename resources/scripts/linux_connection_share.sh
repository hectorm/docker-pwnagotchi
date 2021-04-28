#!/bin/sh

set -eu

UPSTREAM_IFACE=${2:-$(awk '$2 == "00000000" {print($1); exit}' /proc/net/route)}
USB_IFACE=${1:-$(awk '$2 == "000E030A" {print($1); exit}' /proc/net/route)}

iptables -A FORWARD -o "${UPSTREAM_IFACE:?}" -i "${USB_IFACE:?}" -s '10.3.14.0/24' -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o "${UPSTREAM_IFACE:?}" -j MASQUERADE

printf 1 > /proc/sys/net/ipv4/ip_forward
