FROM alpine:3.23

RUN apk add --no-cache busybox bash frr iproute2 iputils tcpdump traceroute tini

COPY conf/daemons conf/frr.conf conf/vtysh.conf /etc/frr/
COPY conf/entrypoint.sh /usr/local/bin/router-entrypoint
RUN chown -R frr:frr /etc/frr \
    && chmod 640 /etc/frr/daemons /etc/frr/frr.conf /etc/frr/vtysh.conf \
    && chmod 755 /usr/local/bin/router-entrypoint

CMD ["/sbin/tini", "--", "/usr/local/bin/router-entrypoint"]
