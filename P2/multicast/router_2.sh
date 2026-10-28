#!/bin/bash

set -e

ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up

ip link add vxlan10 type vxlan id 10 group 239.1.1.1 local 10.0.0.2 dev eth0 dstport 4789

ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1 master br0
ip link set vxlan10 up
ip link set eth1 up
ip link set br0 up
