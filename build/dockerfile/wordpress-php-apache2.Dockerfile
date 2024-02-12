ARG DOCKER_REGISTRY
ARG REGISTRY_USER=csalab
ARG RTAG
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/sipstack:base${RTAG} as builder
WORKDIR /tmp
RUN wget -q https://github.com/WordPress/WordPress/archive/refs/tags/6.4.3.tar.gz && \
    tar -xf 6.4.3.tar.gz

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/php:apache2${RTAG}
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=apache:apache /tmp/WordPress-6.4.3 /var/www/localhost/htdocs
COPY data/passwd-apache2 /etc/passwd
RUN /bin/busybox rm -rf /var/www/localhost/htdocs/index.html && \
    /bin/busybox find /sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox rm -rf /bin/busybox
WORKDIR /var/www/localhost/htdocs
ENTRYPOINT [ "/usr/sbin/httpd", "-DFOREGROUND" ]
