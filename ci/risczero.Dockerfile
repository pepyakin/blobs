# docker build --platform linux/amd64 -f ci/risczero.Dockerfile -t ghcr.io/pepyakin/risczero:0.19 .

FROM ubuntu:20.04 as builder

# TODO: update this
LABEL org.opencontainers.image.source=https://github.com/pepyakin/blobs

ARG RUSTC_VERSION=nightly-2023-10-16

ENV CARGO_INCREMENTAL=0
ENV CARGO_HOME=/cargo
ENV CARGO_TARGET_DIR=/cargo_target
ENV RUSTFLAGS=""
ENV RUSTUP_HOME=/rustup

RUN mkdir -p /cargo && \
    mkdir -p /cargo_target && \
    mkdir -p /rustup

RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        protobuf-compiler \
        curl \
        git \
        llvm \
        clang \
        cmake \
        make \
        libssl-dev \
        pkg-config

RUN \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUSTC_VERSION
RUN $CARGO_HOME/bin/rustup target add wasm32-unknown-unknown

# RUN $CARGO_HOME/bin/cargo install cargo-risczero
# RUN $CARGO_HOME/bin/cargo risczero install

# Install cargo binstall, using it install cargo-risczero, and using it install risc0 toolchain.
RUN curl \
    -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh \
    | bash
RUN $CARGO_HOME/bin/cargo binstall --no-confirm --no-symlinks cargo-risczero
RUN $CARGO_HOME/bin/cargo risczero install
