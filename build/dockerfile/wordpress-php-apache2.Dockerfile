ARG DOCKER_REGISTRY
ARG REGISTRY_USER=csalab
ARG RTAG
ARG PHP_VERSION
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/sipstack:base${RTAG} as builder
ARG IMAGE_VERSION
WORKDIR /tmp
RUN wget -q "https://github.com/WordPress/WordPress/archive/refs/tags/${IMAGE_VERSION}.tar.gz" && \
    tar -xf "${IMAGE_VERSION}.tar.gz"

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/php:${PHP_VERSION}apache2${RTAG}
ARG IMAGE_VERSION
LABEL maintainer="admin@csalab.id"
COPY data/passwd-php-apache2 /etc/passwd
COPY data/group-php-apache2 /etc/group
COPY --from=builder --chown=apache:apache /tmp/WordPress-${IMAGE_VERSION} /var/www/localhost/htdocs
RUN /bin/busybox rm -rf /var/www/localhost/htdocs/index.html && \
    /bin/busybox find /sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox rm -rf /bin/busybox
WORKDIR /var/www/localhost/htdocs
VOLUME /var/www/localhost/htdocs
ENTRYPOINT [ "/usr/sbin/httpd", "-DFOREGROUND" ]
