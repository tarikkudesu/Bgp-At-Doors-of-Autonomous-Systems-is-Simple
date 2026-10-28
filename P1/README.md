
**1. Configure the host**

In the host console:
```
ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up
```

**2. Configure the router**

In the router console, open the FRR shell:
```
vtysh
configure terminal
interface eth0
 ip address 10.0.0.1/24
 no shutdown
end
write
```

**3. Test the connection**

From the host:
```
ping 10.0.0.1
```

If you get replies, they're connected.
