FROM ghcr.io/pepyakin/risczero:0.19 as risczero

FROM ubuntu:20.04 as builder

# TODO: update this
LABEL org.opencontainers.image.source=https://github.com/pepyakin/blobs

ARG RUSTC_VERSION=nightly-2023-10-16

ENV CARGO_INCREMENTAL=0
ENV CARGO_HOME=/cargo
ENV CARGO_TARGET_DIR=/cargo_target
ENV RUSTFLAGS="-Cdebuginfo=0"
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
RUN cd demo/sovereign && $CARGO_HOME/bin/cargo build --locked

FROM ubuntu:20.04 as prod

RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libssl-dev \
        pkg-config

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY --from=builder /cargo_target/debug/sov-demo-rollup /usr/bin/sov-demo-rollup
COPY --from=builder /cargo_target/debug/sov-cli /usr/bin/sov-cli

COPY ./demo/sovereign /sugondat/demo/sovereign
COPY ./ci/rollup_config.docker.toml /sugondat/demo/sovereign/demo-rollup/rollup_config.toml
WORKDIR /sugondat/demo/sovereign/demo-rollup

ENTRYPOINT ["/tini", "--", "/usr/bin/sov-demo-rollup"]
