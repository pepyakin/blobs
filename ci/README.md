# CI infrastructure

## Notes

To check the docker layers, use `dive`.
To see what files gets into the docker context, use `ncdu`.

ncdu -X .gitignore -X .dockerignore

Docker builds use the repository root as context, so we need to use .dockerignore to exclude files.

We strive to base docker images off ubuntu:20.04 to simplify things. Perhaps, we should consider something slimmer.

We rely on stages, and this requires buildkit. So run DOCKER_BUILDKIT=1 if not enabled by default.

There are several workflows and jobs.

There is a buildbase workflow that is triggered either manually or periodically. It builds the 
docker images used for the builds.

There is a CI workflow. It's triggered on each commit? There are several jobs:

1. fmt, designed to run fast and report if there are any fmt style inconsistencies. Should not be blocking I suppose.
2. check. Supposed to run fast.

There is risczero dockerfile, but it's not integrated into buildbase. So you should build it manually.