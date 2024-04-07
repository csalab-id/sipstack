ARG DOCKER_REGISTRY
ARG REGISTRY_USER=csalab
ARG RTAG
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/sipstack:base${RTAG} as builder
ARG IMAGE_VERSION
WORKDIR /tmp
COPY script/wordpress-init.c /tmp
RUN apk add --no-cache musl-dev gcc && \
    wget -q "https://github.com/WordPress/WordPress/archive/refs/tags/${IMAGE_VERSION}.tar.gz" && \
    tar -xf "${IMAGE_VERSION}.tar.gz" && \
    gcc wordpress-init.c -o startup

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/sipstack:php-fpm-nginx${RTAG}
ARG IMAGE_VERSION
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=nobody:nobody /tmp/WordPress-${IMAGE_VERSION} /www
COPY --from=builder /tmp/startup /usr/sbin/startup
COPY data/passwd /etc/passwd
COPY config/nginx.conf /etc/nginx/http.d/default.conf
RUN /bin/busybox chown nginx:nginx /var/lib/nginx && \
    /bin/busybox chown nginx:nginx /var/lib/nginx/tmp/ && \
    /bin/busybox find /sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/sbin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox find /usr/bin -type l -exec /bin/busybox unlink {} \; && \
    /bin/busybox rm -rf /bin/busybox
WORKDIR /www
ENTRYPOINT [ "/usr/sbin/startup" ]
