ARG DOCKER_REGISTRY
ARG REGISTRY_USER=csalab
ARG RTAG
ARG PHP_VERSION
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/sipstack:base${RTAG} as builder
WORKDIR /tmp
RUN wget -q https://github.com/WordPress/WordPress/archive/refs/tags/6.4.3.tar.gz && \
    tar -xf 6.4.3.tar.gz

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/php:${PHP_VERSION}fpm${RTAG}
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=nobody:nobody /tmp/WordPress-6.4.3 /www
COPY data/passwd-php-fpm /etc/passwd
RUN /bin/busybox find /sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox rm -rf /bin/busybox
WORKDIR /www
ENTRYPOINT [ "/usr/sbin/php-fpm83", "-F" ]
