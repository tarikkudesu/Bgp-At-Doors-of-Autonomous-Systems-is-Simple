#!/bin/bash
set -e

# Docker sysctls or GNS3 privileges must allow forwarding in this namespace.
if [[ $(cat /proc/sys/net/ipv4/ip_forward) != 1 ]]; then
    sysctl -w net.ipv4.ip_forward=1
fi
mkdir -p /run/frr
chown frr:frr /run/frr

# Use the package's daemon selection and restart machinery.
source /usr/lib/frr/frrcommon.sh
exec /usr/lib/frr/watchfrr $(daemon_list)
