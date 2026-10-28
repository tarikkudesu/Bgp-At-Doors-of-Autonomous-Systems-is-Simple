# BADASS — BGP At Doors of Autonomous Systems is Simple

A networking lab using **GNS3**, **Docker**, and **FRRouting (FRR)** to explore VXLAN and BGP EVPN.

## Project parts

- **[P1](P1/README.md):** Set up a host and router, then test basic connectivity.
- **[P2](P2/README.md):** Connect hosts through VXLAN using static and multicast modes.
- **[P3](P3/README.md):** Build a BGP EVPN network with OSPF and a route reflector.

## Requirements

- GNS3
- Docker with Docker Compose
- Make

## Getting started

1. Build the Docker images for the part you want to run:

   ```sh
   cd P1
   make build
   ```

2. Import that part's `.gns3project` file into GNS3 and use the built host and router images for its nodes.
3. Start the nodes and follow the configuration steps in the part's README.
4. Use `ping` between devices to check connectivity.

Configuration scripts are included in each part for reference.
