ARG DOCKER_REGISTRY=
ARG REGISTRY_USER=csalab
ARG ARCH=
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/wordpress:debug${ARCH} as builder
WORKDIR /tmp
COPY script/wordpress-init.c /tmp
RUN wget -q https://github.com/WordPress/WordPress/archive/refs/tags/6.4.2.tar.gz && \
    tar -xf 6.4.2.tar.gz && \
    gcc wordpress-init.c -o wordpress-init

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/wordpress:devel${ARCH}
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=nobody:nobody /tmp/WordPress-6.4.2 /www
COPY --from=builder /tmp/wordpress-init /wordpress-init
COPY data/passwd /etc/passwd
COPY config/nginx.conf /etc/nginx/http.d/default.conf
RUN /bin/busybox find /sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox rm -rf /bin/busybox
WORKDIR /www
ENTRYPOINT [ "/wordpress-init" ]
