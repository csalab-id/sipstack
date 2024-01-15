ARG DOCKER_REGISTRY=
ARG REGISTRY_USER=csalab
ARG ARCH=
FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/wordpress:debug${ARCH} as builder
WORKDIR /tmp
COPY script/wordpress-init.c /tmp
RUN wget -q https://github.com/WordPress/WordPress/archive/refs/tags/6.4.2.tar.gz && \
    tar -xf 6.4.2.tar.gz && \
    gcc wordpress-init.c -o wordpress-init && \
    echo "root:x:0:0:root:/root:/bin/ash" > /tmp/passwd && \
    echo "nginx:x:10000:10000:Nginx:/home/nginx:/sbin/nologin" >> /tmp/passwd && \
    echo "nobody:x:10001:10001:Nobody:/home/nobody:/sbin/nologin" >> /tmp/passwd

FROM ${DOCKER_REGISTRY}${REGISTRY_USER}/wordpress:devel${ARCH}
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=nobody:nobody /tmp/WordPress-6.4.2 /www
COPY --from=builder /tmp/passwd /etc/passwd
COPY --from=builder /tmp/wordpress-init /wordpress-init
COPY data/passwd /etc/passwd
COPY config/nginx.conf /etc/nginx/http.d/default.conf
RUN /bin/rm -rf /bin/busybox
WORKDIR /www
ENTRYPOINT [ "/wordpress-init" ]
