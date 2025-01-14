# This Dockerfile depends on several additional contexts, specifically:
#
# - sugondat-release-bins — see buildbase-sugondat.Dockerfile
#
# docker build -f ci/demostand.Dockerfile -t ghcr.io/pepyakin/blobs-demostand:latest .

# We would start from zombienet image, since it's a chunky boy and it is not worth it to try to pick
# things from it.
FROM ubuntu:20.04

# RUN apt update \
#     && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y multitail npm \
#     && rm -rf /var/lib/apt/lists/* 
# RUN npm install -g @zombienet/cli


RUN apt update \
    && DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* 


ADD https://github.com/paritytech/zombienet/releases/download/v1.3.86/zombienet-linux-x64 /usr/bin/zombienet
RUN chmod +x /usr/bin/zombienet

COPY --from=parity/polkadot:v1.4.0 /usr/bin/polkadot /usr/bin/
COPY --from=parity/polkadot:v1.4.0 /usr/lib/polkadot/polkadot-prepare-worker /usr/bin/
COPY --from=parity/polkadot:v1.4.0 /usr/lib/polkadot/polkadot-execute-worker /usr/bin/

COPY --from=ghcr.io/pepyakin/blobs-node:latest /usr/bin/sugondat-node /usr/bin/
COPY ./testnet.toml /testnet.toml

EXPOSE 9988

VOLUME /zombienet
CMD ["zombienet", "spawn", "--provider=native", "-d/zombienet/data", "/testnet.toml"]
