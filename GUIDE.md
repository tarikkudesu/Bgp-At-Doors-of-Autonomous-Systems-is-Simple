# The Story of Data Center Networking: From VLANs to BGP EVPN

*A beginner-friendly history, told in order, of how we got from "just plug it in" to VXLAN + BGP EVPN.*

---

## 1. The starting point: VLANs, and why they broke

Back in the early data center days, if you wanted to separate traffic — say, keep the finance team's servers isolated from the marketing team's — you used **VLANs** (802.1Q). A VLAN is just a tag stuck on an Ethernet frame that says "I belong to group 42." Switches use that tag to keep groups separated on the same physical wiring.

This worked fine for a while. But then cloud computing happened.

**The problem:** A VLAN tag is only 12 bits long. That means a maximum of **4,094 usable VLANs** on a network. That sounds like a lot — until you're a cloud provider (or a big enterprise trying to act like one) hosting thousands of tenants, each of whom might need several isolated networks. 4,094 runs out embarrassingly fast.

VLANs also don't stretch well. They're a Layer 2 (Ethernet) concept, and Layer 2 networks don't like being spread across many switches and long distances — loops, broadcast storms, and Spanning Tree Protocol headaches pile up.

So the industry needed: **way more than 4,094 isolated networks**, and the ability to stretch Layer 2 connectivity **over an IP network** instead of raw Ethernet wiring.

---

## 2. Circa 2010: VMware's problem, and why the "obvious" answers failed

Around 2010, **AWS** had exploded in popularity. VMware — the company that dominated server virtualization — wanted to let its enterprise customers build their own AWS-like "private clouds": lots of virtual machines, lots of tenants, all needing isolated, flexible virtual networks.

VMware needed a tunneling technology to carry Ethernet (L2) traffic between hosts, over an ordinary IP network, at massive scale. A few existing options were considered — and rejected:

- **MPLS**: This was already used by ISPs to do exactly this kind of tunneling. But MPLS is complex to operate and wasn't something typical enterprise IT staff (or affordable enterprise switches) could easily run. Too heavy for the job.
- **GRE (Generic Routing Encapsulation)**: This is a simple, generic IP tunnel — wrap any packet inside another IP packet. It seemed like the natural choice. But it had two problems:
  1. **Firewalls hate it.** GRE isn't TCP or UDP — it's its own IP protocol number. Getting it through a corporate firewall means special-casing a whole protocol, not just opening a port. A UDP port, by contrast, is trivial to permit.
  2. **It's too generic.** GRE doesn't say *why* you're tunneling — it's used for all sorts of things. That ambiguity meant switch hardware vendors couldn't build dedicated fast-path silicon just for "network virtualization tunnels," because GRE headers could mean anything.

So the requirements were clear: **UDP-based** (firewall-friendly, and naturally load-balances across IP networks since routers already know how to spread UDP/IP flows across multiple paths), with a **dedicated, unambiguous purpose** (so hardware could accelerate it), and a **much bigger namespace** than VLAN's 4,094.

---

## 3. VXLAN is born (and why its header looks weird)

This is where **VXLAN (Virtual Extensible LAN)** comes in, designed largely by engineers at Cisco (including Dinesh Dutt, one of its authors) working with VMware.

**What VXLAN actually does:** it takes an original Ethernet frame (from a VM), and wraps it inside UDP, then inside IP. The devices doing this wrapping/unwrapping are called **VTEPs** (VXLAN Tunnel Endpoints). Everything in between — ordinary routers and switches — just sees a boring UDP/IP packet and forwards it normally, load-balancing it across multiple paths (ECMP) like any other IP traffic. To make that load-balancing actually spread flows out nicely, the ingress VTEP computes a pseudo-random **UDP source port** based on a hash of the original inner packet — so different flows inside the tunnel still get spread across different physical paths.

The identifier replacing the VLAN tag is the **VNI (VXLAN Network Identifier)** — **24 bits**, giving about **16 million** possible virtual networks instead of 4,094. Problem #1 (not enough segments) — solved.

**Why the header has odd reserved bits and an "always-1" bit:** Cisco already had two sibling technologies — **OTV** (a proprietary data-center-interconnect overlay) and **LISP** (a locator/ID separation protocol heading toward IETF standardization). Cisco wanted VXLAN's header to stay structurally compatible with those, so certain bit positions were reserved or fixed even though they do nothing in VXLAN itself. That's why what could've been a lean 4-byte header ended up 8 bytes — an artifact of internal protocol politics, not a technical requirement of VXLAN itself.

**What VXLAN did NOT solve:** how do VTEPs learn *where* (behind which other VTEP) a given MAC address lives?

---

## 4. The next problem: "flood and learn" doesn't scale

Early VXLAN leaned on the same trick traditional Ethernet switches always used: **flood-and-learn**. If a VTEP doesn't know where a destination MAC is, it floods the frame to *every* other VTEP interested in that VNI, and learns the real location once a reply comes back.

To distribute this flooding (and other BUM traffic — **Broadcast, Unknown-unicast, Multicast**) efficiently, early VXLAN designs used **IP multicast** in the underlay: one flooded frame, replicated efficiently by multicast-capable routers to everyone who needs it.

**The problem:** Running IP multicast (PIM, IGMP, rendezvous points, etc.) across a data center underlay is operationally painful. Most data center operators didn't want to manage multicast just to make VXLAN's flooding efficient. And flood-and-learn itself is wasteful — every new MAC anywhere triggers flooding everywhere, and ARP requests (which are inherently broadcast) get flooded across the whole fabric too, even though there's often a smarter way.

The industry realized: **VXLAN needed a real control plane** — a way for VTEPs to proactively *tell* each other "here's a MAC/IP I know about," instead of relying purely on flooding and passive learning.

---

## 5. BGP EVPN: adding a brain to VXLAN

Enter **BGP EVPN** (Ethernet VPN, carried over Multiprotocol BGP).

Why BGP, of all things? Because BGP was already the protocol the entire internet trusted for scale, and it already had a proven ability to carry different kinds of routing information (that's what "Multiprotocol" BGP means) via **address families**. So instead of inventing a brand-new control-plane protocol from scratch, the same MP-BGP that carries IP routes was extended with a new address family: **L2VPN EVPN**.

With BGP EVPN, VTEPs use BGP sessions to advertise structured information instead of relying on flooding:

- **Route Type 2** — "here's a MAC address (and optionally its IP) that lives behind me." This is the big one: it lets a VTEP learn remote MAC/IP bindings *proactively*, via BGP, instead of waiting for flood-and-learn traffic.
- **Route Type 3** — "here's which VNIs I'm a VTEP for," used to build the BUM-replication list without needing multicast — this enables **ingress replication** (the source VTEP just unicasts a copy of the BUM frame to every relevant remote VTEP itself, no multicast required in the underlay).
- **Route Type 1** and **Route Type 4** — related to **multihoming**: if a server is dual-connected to two different leaf switches (an "Ethernet Segment," identified by an **ESI**), these route types coordinate which leaf is the **Designated Forwarder** for BUM traffic, and prevent loops via **split-horizon** rules.
- **Route Type 5** — "here's an IP prefix reachable through me," used for proper Layer 3 routing between different VNIs/subnets (not just L2 MAC reachability).

**A nice side effect of Route Type 2:** since VTEPs now know remote MAC-to-IP bindings via BGP, they can do **ARP suppression** — if a VM asks "who has this IP," the local VTEP can just answer locally from its BGP-learned table instead of flooding the ARP request across the whole fabric. Less flooding, less noise, more scale.

**Result:** the multicast requirement is gone (solved by Route Type 3 + ingress replication), flood-and-learn is minimized (solved by Route Type 2), and hardware/software finally had a scalable way to do MAC learning and multi-tenant isolation across a fabric. Problem #2 (no real control plane) — solved.

---

## 6. Routing between tenants: L2VNI, L3VNI, and the anycast gateway

Once VXLAN + BGP EVPN gives you scalable Layer 2 segments, a new need shows up: VMs in *different* subnets (different VNIs) still need to talk to each other — that's routing, not switching.

- An **L2VNI** is a VNI that represents a single bridge domain/subnet — basically "VLAN, but VXLAN-flavored."
- An **L3VNI** is a special VNI used to carry *already-routed* traffic between subnets, tied to a **VRF** (a virtual routing table, so different tenants' IP spaces don't collide).

To make routing between subnets efficient in a distributed fabric (rather than funneling everything through one central router — the old-school bottleneck), the concept of a **distributed anycast gateway** appeared: every leaf switch presents the *same* gateway IP/MAC for a given subnet's SVI. A VM's default gateway is always "right there" on whichever leaf it's connected to, no matter which leaf that is. This is implemented as either:
- **Asymmetric IRB** — routing happens at ingress, then the packet is VXLAN-bridged in the destination VNI (requires every leaf to know every VNI).
- **Symmetric IRB** — routing happens at ingress *and* egress, with the L3VNI carrying the packet in between (more scalable — leaves don't need to know VNIs they don't locally host).

---

## 7. Putting it on physical hardware: the spine-leaf fabric

All of this needs a physical topology that actually delivers the ECMP, low-latency, non-blocking behavior VXLAN/BGP EVPN assume. That's the now-standard **spine-leaf (Clos) topology**:

- **Leaf switches** connect to servers/hosts and act as the **VTEPs**.
- **Spine switches** exist purely to interconnect leaves, with every leaf connected to every spine — giving multiple equal-cost paths (hence ECMP) between any two leaves.
- **Border leaves** are the leaves that connect the fabric to the outside world (internet, other data centers, etc.).

The underlay running on this physical topology is usually just **eBGP** (often "eBGP unnumbered," to avoid manually addressing every point-to-point link) or an IGP like OSPF/IS-IS, with **loopback interfaces (/32)** on each leaf acting as the stable, always-reachable VTEP source address — because a VTEP's tunnel endpoint needs to survive any single physical link going down, which is why it's a loopback and not a physical interface IP.

---

## 8. The story in one line

> VLANs ran out of room and couldn't stretch over IP → GRE and MPLS were tried and rejected for tunneling (too generic / too complex) → VXLAN was built as a UDP-based tunnel with a 24-bit namespace, using flood-and-learn and (originally) IP multicast to handle unknown traffic → multicast in the underlay was operationally painful and flooding didn't scale → BGP EVPN was added as a real control plane (reusing trusted, battle-tested BGP) so VTEPs could proactively learn MACs/IPs, suppress ARP flooding, replicate BUM traffic without multicast, and support multihoming and inter-subnet routing → all of it runs on a spine-leaf physical fabric designed specifically to give VXLAN's IP-based load balancing lots of equal-cost paths to spread across.

That's BADASS: you're essentially rebuilding, piece by piece, the exact sequence of problems and solutions the real data center industry went through between roughly 2008 and today.

---

*Sources: "BGP in the Data Center" and "EVPN in the Data Center" (Dinesh Dutt, O'Reilly).*