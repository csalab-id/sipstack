ARG DOCKER_REGISTRY=
FROM ${DOCKER_REGISTRY}csalab/wordpress:debug as builder
WORKDIR /tmp
RUN wget https://github.com/WordPress/WordPress/archive/refs/tags/6.4.2.tar.gz && \
tar -xf 6.4.2.tar.gz

FROM ${DOCKER_REGISTRY}csalab/wordpress:devel
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=nginx:nginx /tmp/WordPress-6.4.2 /www
WORKDIR /www
ENTRYPOINT ["/usr/bin/php" "-S" "0.0.0.0:8080"]
