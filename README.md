# devcontainer-agyn

## Build arguments

`GH_PR_REVIEW_VERSION` can be overridden independently for releases whose
per-architecture SHA-256 digests are encoded in the Dockerfile. Other
`gh-pr-review` releases must be built with the matching checksum override for
the target architecture:

```sh
docker build \
  --build-arg GH_PR_REVIEW_VERSION=vX.Y.Z \
  --build-arg GH_PR_REVIEW_LINUX_AMD64_SHA256=<linux-amd64-sha256> \
  --build-arg GH_PR_REVIEW_LINUX_ARM64_SHA256=<linux-arm64-sha256> \
  .
```

For single-platform builds of an unmapped release, only the checksum for the
target architecture is required.

`OUTLINE_CLI_VERSION` defaults to `v0.3.0`. That version's Linux amd64 and
arm64 SHA-256 digests are encoded in the Dockerfile. Other `outline-cli`
releases must be built with the matching checksum override for the target
architecture:

```sh
docker build \
  --build-arg OUTLINE_CLI_VERSION=vX.Y.Z \
  --build-arg OUTLINE_CLI_LINUX_AMD64_SHA256=<linux-amd64-sha256> \
  --build-arg OUTLINE_CLI_LINUX_ARM64_SHA256=<linux-arm64-sha256> \
  .
```

For single-platform builds of an unmapped release, only the checksum for the
target architecture is required.
