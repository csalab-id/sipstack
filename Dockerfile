FROM csalab/wordpress:debug-amd64 as builder
WORKDIR /tmp
RUN wget https://github.com/WordPress/WordPress/archive/refs/tags/6.4.2.tar.gz && \
tar -xf 6.4.2.tar.gz

FROM csalab/wordpress:dev-amd64
LABEL maintainer="admin@csalab.id"
COPY --from=builder --chown=nonroot:nonroot /tmp/WordPress-6.4.2 /app
WORKDIR /app
ENTRYPOINT ["/usr/bin/php" "-S" "0.0.0.0:8080"]
