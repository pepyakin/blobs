# This Dockerfile depends on several additional contexts, specifically:
#
# - sugondat-release-bins — see buildbase-sugondat.Dockerfile
#
# docker build \
#   -f ci/demostand.Dockerfile \
#   --build-context sugondat-release-bins=docker-image://ghcr.io/pepyakin/blobs-buildbase-sugondat-release-bin:latest \
#   .

# We would start from zombienet image, since it's a chunky boy and it is not worth it to try to pick
# things from it.
FROM paritytech/zombienet

COPY --from=parity/polkadot:v1.4.0 /usr/bin/polkadot /usr/bin/polkadot
COPY --from=sugondat-release-bins /usr/bin/sugondat-node /usr/bin/sugondat-node
COPY ./testnet.toml /tmp/testnet.toml

ENTRYPOINT zombienet
CMD ["spawn --provider native /tmp/testnet.toml"]
