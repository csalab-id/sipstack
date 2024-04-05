ARG DOCKER_REGISTRY
ARG REGISTRY_USER=csalab
ARG RTAG
ARG PHP_VERSION
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/sipstack:base${RTAG} as builder
ARG IMAGE_VERSION
WORKDIR /tmp
RUN wget -q "https://github.com/WordPress/WordPress/archive/refs/tags/${IMAGE_VERSION}.tar.gz" && \
    tar -xf "${IMAGE_VERSION}.tar.gz"

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/php:${PHP_VERSION}fpm${RTAG}
ARG IMAGE_VERSION
LABEL maintainer="admin@csalab.id"
COPY data/passwd-php-fpm /etc/passwd
COPY data/group-php-fpm /etc/group
COPY --from=builder --chown=nobody:nobody /tmp/WordPress-${IMAGE_VERSION} /var/www/html
RUN /bin/busybox sed -i "s/127.0.0.1:9000/0.0.0.0:9000/g" /etc/php*/php-fpm.d/www.conf && \
    /bin/busybox sed -i "s/;chdir = \/var\/www/chdir = \/var\/www\/html/g" /etc/php*/php-fpm.d/www.conf && \
    /bin/busybox find /sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox rm -rf /bin/busybox
WORKDIR /var/www/html
VOLUME /var/www/html
ENTRYPOINT [ "/usr/sbin/php-fpm83", "-F" ]
