# docker build --platform linux/amd64 -f ci/demo-gm.Dockerfile -t ghcr.io/pepyakin/blobs-demo-gm:latest .

FROM golang:1.21 as builder

# TODO: update this
LABEL org.opencontainers.image.source=https://github.com/pepyakin/blobs

RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl

# Install ignite CLI
RUN curl https://get.ignite.com/cli@v0.27.1! | bash

# it seems that `go work` is broken in docker. Let's just copy the sugondat package.
COPY ./demo/rollkit /demo-rollkit
COPY ./adapters/rollkit /demo-rollkit/sugondat
# Patch the source file
RUN sed -i 's/\"sugondat\"/\"gm\/sugondat\"/' /demo-rollkit/cmd/gmd/cmd/root.go
RUN rm /demo-rollkit/sugondat/go.*
WORKDIR /demo-rollkit

RUN go mod download && go mod verify
RUN ignite chain build

FROM golang:1.21 AS prod

COPY --from=builder /go/bin/gmd /usr/local/bin/gmd
COPY ./demo/rollkit/init-local.sh /root/init-local.sh
WORKDIR /root
ENTRYPOINT /usr/local/bin/gmd
