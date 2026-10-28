
# Static mode

**Addressing plan**

| Device | Interface | IP |
|---|---|---|
| router_tamehri-1 | e0 (underlay) | 10.0.0.1/24 |
| router_tamehri-2 | e0 (underlay) | 10.0.0.2/24 |
| host_tamehri-1 | e1 | 30.1.1.1/24 |
| host_tamehri-2 | e1 | 30.1.1.2/24 |

The switch needs no configuration. It just connects the two routers' `e0` interfaces.

**Step 1: Configure the underlay (both routers)**

On router_tamehri-1:
```
ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up
```

On router_tamehri-2:
```
ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up
```

Test it: `ping 10.0.0.2` from router 1. Don't continue until this works.

**Step 2: Create the VXLAN tunnel (static mode)**

On router_tamehri-1:
```
ip link add vxlan10 type vxlan id 10 local 10.0.0.1 remote 10.0.0.2 dstport 4789 dev eth0
```

On router_tamehri-2:
```
ip link add vxlan10 type vxlan id 10 local 10.0.0.2 remote 10.0.0.1 dstport 4789 dev eth0
```

Here `id 10` is the VNI, and `remote` is the static part, hardcoding the other VTEP's IP.

**Step 3: Bridge the tunnel with the host-facing port (both routers)**

```
ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1 master br0
ip link set vxlan10 up
ip link set eth1 up
ip link set br0 up
```

**Step 4: Configure the hosts**

On host_tamehri-1:
```
ip addr add 30.1.1.1/24 dev eth1
ip link set eth1 up
```

On host_tamehri-2:
```
ip addr add 30.1.1.2/24 dev eth1
ip link set eth1 up
```

**Step 5: Test**

From host_tamehri-1: `ping 192.168.100.2`. If it replies, your VXLAN works.

**If it doesn't work**
- Check that the underlay ping works (Step 1).
- Run `ip -d link show vxlan10` to confirm the VNI and IPs are right.
- Run `bridge fdb show dev vxlan10` to see the learned MACs.
- Run `tcpdump -i eth0 udp port 4789` on a router while pinging, and you should see the VXLAN packets.
- If small pings work but larger transfers fail, it's an MTU issue, since VXLAN adds 50 bytes. Lower the hosts' MTU with `ip link set eth1 mtu 1400`.

Once this works, you can move on to multicast mode by replacing `remote ...` with `group 239.1.1.1`.

# Dynamic Multicast

**Addressing plan**

| Device | Interface | IP |
|---|---|---|
| router_tamehri-1 | e0 (underlay) | 10.0.0.1/24 |
| router_tamehri-2 | e0 (underlay) | 10.0.0.2/24 |
| host_tamehri-1 | e1 | 30.1.1.1/24 |
| host_tamehri-2 | e1 | 30.1.1.2/24 |

**Step 1: Underlay (both routers)**

router_tamehri-1:
```
ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up
```

router_tamehri-2:
```
ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up
```

Test with `ping 10.0.0.2` from router 1.

**Step 2: Create the VXLAN interface (multicast mode)**

router_tamehri-1:
```
ip link add vxlan10 type vxlan id 10 group 239.1.1.1 local 10.0.0.1 dev eth0 dstport 4789
```

router_tamehri-2:
```
ip link add vxlan10 type vxlan id 10 group 239.1.1.1 local 10.0.0.2 dev eth0 dstport 4789
```

`group` replaces `remote`, and `dev eth0` tells Linux which interface should join the multicast group.

**Step 3: Bridge the tunnel with the host-facing port (both routers)**

```
ip link add br0 type bridge
ip link set vxlan10 master br0
ip link set eth1 master br0
ip link set vxlan10 up
ip link set eth1 up
ip link set br0 up
```

**Step 4: Hosts**

host_tamehri-1:
```
ip addr add 30.1.1.1/24 dev eth1
ip link set eth1 up
```

host_tamehri-2:
```
ip addr add 30.1.1.2/24 dev eth1
ip link set eth1 up
```

**Step 5: Test**

From host_tamehri-1: `ping 192.168.100.2`
