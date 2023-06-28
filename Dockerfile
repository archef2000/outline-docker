ARG NODE_IMAGE="node:16.18.0-alpine3.16"

FROM ${NODE_IMAGE} AS builder

COPY empty_bin.c /
WORKDIR /
RUN apk add build-base \
    && gcc -o empty_bin empty_bin.c

FROM ${NODE_IMAGE} AS downloader

ARG OUTLINE_VERSION="manager-v1.14.0"

RUN apk add --no-cache --upgrade unzip wget \
    && wget https://codeload.github.com/Jigsaw-Code/outline-server/zip/refs/tags/${OUTLINE_VERSION} -O outline.zip \
    && unzip outline.zip -d /outline_zip \
    && mv /outline_zip/$(ls /outline_zip) /outline \
    && prometheus_build_arch=$(uname -m | sed 's/armv7l/armv7/;s/armv[0-9]l/arm/;s/aarch64/arm64/;s/x86_64/amd64/') \
    && sed -i "s/amd64/$prometheus_build_arch/g" /outline/third_party/prometheus/Makefile \
    && outline_build_arch=$(uname -m | sed 's/armv7l/armv7/;s/armv[0-9]l/arm/;s/aarch64/arm64/') \
    && sed -i "s/x86_64/$outline_build_arch/g" /outline/third_party/outline-ss-server/Makefile

FROM ${NODE_IMAGE} AS build

RUN apk add --no-cache --upgrade bash make perl-utils

WORKDIR /

COPY --from=downloader /outline/package.json /outline/package-lock.json ./
COPY --from=downloader /outline/src/shadowbox/package.json src/shadowbox/

RUN npm ci

COPY --from=downloader /outline/scripts scripts/
COPY --from=downloader /outline/src src/
COPY --from=downloader /outline/tsconfig.json ./
COPY --from=downloader /outline/third_party third_party
COPY --from=builder /empty_bin /empty_bin

RUN ROOT_DIR=/ npm run action shadowbox/server/build

FROM ${NODE_IMAGE}

ARG OUTLINE_VERSION="manager-v1.14.0"

LABEL shadowbox.node_version=16.18.0
LABEL shadowbox.outline.release="${OUTLINE_VERSION}"

RUN apk add --no-cache --upgrade coreutils curl openssl jq

COPY --from=downloader /outline/src/shadowbox/scripts scripts/
COPY --from=downloader /outline/src/shadowbox/scripts/update_mmdb.sh /etc/periodic/weekly/update_mmdb

RUN /etc/periodic/weekly/update_mmdb

RUN mkdir -p /data

WORKDIR /opt/outline-server

COPY --from=build /build/shadowbox/ .
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENV CERTIFICATE_FILE="/data/server.crt"
ENV PRIVATE_KEY_FILE="/data/server.key"
ENV SB_STATE_DIR="/data"
ENV LOG_LEVEL="warn"
ENV METRICS="false"
ENV ACCESS_KEY_PORT=9999
ENV API_PORT=8081
ENV DOMAIN=""
ENV METRICS_URL="https://prod.metrics.getoutline.org"

ENTRYPOINT /entrypoint.sh
