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
        make

RUN \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUSTC_VERSION
RUN $CARGO_HOME/bin/rustup target add wasm32-unknown-unknown

WORKDIR /sugondat
COPY . /sugondat

# The stages below are targets.

FROM builder AS sugondat-node-release
RUN $CARGO_HOME/bin/cargo build -p sugondat-node --locked --release

FROM builder AS sugondat-workspace-check
RUN $CARGO_HOME/bin/cargo check --workspace --locked

FROM builder AS sugondat-workspace-test
RUN $CARGO_HOME/bin/cargo test --workspace --no-run --locked

FROM builder AS basebuild-sugondat-shim-release
RUN $CARGO_HOME/bin/cargo build -p sugondat-shim --locked --release
# ↑ builds /cargo_target/release/sugondat-shim

FROM builder as sugondat-release-bin-build
RUN $CARGO_HOME/bin/cargo build -p sugondat-shim -p sugondat-node --locked --release

FROM ubuntu:20.04 as sugondat-release-bin
COPY --from=sugondat-release-bin-build /cargo_target/release/sugondat-node /usr/bin/
COPY --from=sugondat-release-bin-build /cargo_target/release/sugondat-shim /usr/bin/

# docker build --platform linux/amd64 -f ci/buildbase-sugondat.Dockerfile --target sugondat-node -t ghcr.io/pepyakin/blobs-node:latest .
FROM ubuntu:20.04 as sugondat-node
COPY --from=sugondat-release-bin-build /cargo_target/release/sugondat-node /usr/bin/
# TODO: EXPOSE
# TODO: CMD
ENTRYPOINT /usr/bin/sugondat-node

# docker build --platform linux/amd64 -f ci/buildbase-sugondat.Dockerfile --target sugondat-shim -t ghcr.io/pepyakin/blobs-shim:latest .
FROM ubuntu:20.04 as sugondat-shim

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY --from=sugondat-release-bin-build /cargo_target/release/sugondat-shim /usr/bin/

# Install `curl` to enable health check.
RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl

EXPOSE 10995

# See https://github.com/thrumdev/blobs/issues/112
ENTRYPOINT ["/tini", "--", "/usr/bin/sugondat-shim"]
CMD ["serve", "-p", "10995"]
