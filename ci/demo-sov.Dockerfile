FROM ghcr.io/pepyakin/risczero:0.19 as risczero

FROM ubuntu:20.04

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

# Install cargo binstall, using it install cargo-risczero, and using it install risc0 toolchain.
RUN \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUSTC_VERSION

COPY --from=risczero $CARGO_HOME/bin/cargo-risczero $CARGO_HOME/bin/cargo-risczero
COPY --from=risczero $CARGO_HOME/bin/r0vm $CARGO_HOME/bin/r0vm
COPY --from=risczero $RUSTUP_HOME/toolchains/risc0 $RUSTUP_HOME/toolchains/risc0

WORKDIR /sugondat
COPY . /sugondat

ENV CONSTANTS_MANIFEST=/sugondat/demo/sovereign/constants.json
RUN cd demo/sovereign && $CARGO_HOME/bin/cargo build --locked --release
