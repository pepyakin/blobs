# CI infrastructure

## Notes

To check the docker layers, use `dive`.
To see what files gets into the docker context, use `ncdu`.

ncdu -X .gitignore -X .dockerignore

Docker builds use the repository root as context, so we need to use .dockerignore to exclude files.

We use ubuntu:20.04 to simplify things. Perhaps, we should consider something else.
