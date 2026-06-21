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
  .
```

For multi-platform builds of an unmapped release, pass both
`GH_PR_REVIEW_LINUX_AMD64_SHA256` and `GH_PR_REVIEW_LINUX_ARM64_SHA256`.
