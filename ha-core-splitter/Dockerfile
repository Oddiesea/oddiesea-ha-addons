# Home Assistant's base image is Alpine, so this binary is built on musl.
# The builder compiles on the target architecture, which avoids a cross file.
ARG BUILD_FROM=ghcr.io/home-assistant/base:3.23

FROM rust:1-alpine AS build
RUN apk add --no-cache build-base pkgconfig dbus-dev
WORKDIR /src
COPY Cargo.toml Cargo.lock ./
COPY src ./src
# The Alpine Rust image links statically, and Alpine has no static libdbus.
# A shared link runs on the Home Assistant base image, which has musl and libdbus.
RUN RUSTFLAGS="-C target-feature=-crt-static" cargo build --release --features ble

FROM ${BUILD_FROM}

RUN apk add --no-cache bluez dbus

COPY --from=build /src/target/release/coresplitter /usr/bin/coresplitter
COPY rootfs /

LABEL \
    org.opencontainers.image.title="Home Assistant Add-on: MeshCore TCP Proxy" \
    org.opencontainers.image.description="Share one MeshCore companion radio over TCP." \
    org.opencontainers.image.source="https://github.com/Oddiesea/oddiesea-ha-addons" \
    org.opencontainers.image.licenses="GPL-3.0"
