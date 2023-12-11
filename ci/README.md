# CI infrastructure

## Notes

To check the docker layers, use `dive`.
To see what files gets into the docker context, use `ncdu`.

ncdu -X .gitignore -X .dockerignore

Docker builds use the repository root as context, so we need to use .dockerignore to exclude files.

We strive to base docker images off ubuntu:20.04 to simplify things. Perhaps, we should consider something slimmer.

We rely on a fresh docker: we are assuming buildkit, multiple build contexts, etc.
Running with DOCKER_BUILDKIT=1 may be necessary.

There are several workflows and jobs.

There is a buildbase workflow that is triggered either manually or periodically. It builds the 
docker images used for the builds.

There is a CI workflow. It's triggered on each commit? There are several jobs:

1. fmt, designed to run fast and report if there are any fmt style inconsistencies. Should not be blocking I suppose.
2. check. Supposed to run fast.

There is risczero dockerfile, but it's not integrated into buildbase. So you should build it manually.

Constraints: the dockerfiles are written in a way that they can fit into the runners. They don't have
much RAM or disk space available. Therefore, we don't want to run builds in parallel.

TODO: rename dir from CI to docker
TODO: move docker-compose.yml to docker
TODO: rename the buildbase-sugondat.Dockerfile to sugondat.Dockerfile as it combines different stages
TODO: rename the stages in that dockerfile to have buildbase.
TODO: create/move CI.md into docs?
