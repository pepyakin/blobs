# docker build --platform linux/amd64 -f ci/buildbase-sugondat.Dockerfile --target sugondat-node-release -t ghcr.io/pepyakin/blobs-buildbase-sugondat-node-release:latest .

FROM ubuntu:20.04 as builder

# TODO: update this
LABEL org.opencontainers.image.source=https://github.com/pepyakin/blobs

ARG RUSTC_VERSION=nightly-2023-10-16

ENV CARGO_INCREMENTAL=0
ENV CARGO_HOME=/cargo
ENV CARGO_TARGET_DIR=/cargo_target
ENV RUSTFLAGS=""
ENV RUSTUP_HOME=/rustup
ENV WASM_BUILD_WORKSPACE_HINT=/sugondat

RUN mkdir -p /cargo
RUN mkdir -p /cargo_target
RUN mkdir -p /rustup

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
        make

WORKDIR /sugondat
COPY . /sugondat

RUN \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUSTC_VERSION
RUN $CARGO_HOME/bin/rustup target add wasm32-unknown-unknown

FROM builder AS sugondat-node-release

RUN $CARGO_HOME/bin/cargo build -p sugondat-node --locked --release

FROM builder AS sugondat-workspace-check

RUN $CARGO_HOME/bin/cargo check --workspace --locked

FROM builder AS sugondat-workspace-test

RUN $CARGO_HOME/bin/cargo test --workspace --no-run --locked

FROM builder AS sugondat-shim-release

RUN $CARGO_HOME/bin/cargo build -p sugondat-shim --locked --release
