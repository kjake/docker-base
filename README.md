# docker-base

My base docker image, forked from chambana-net/docker-base, based on debian.

The image is built from `debian:testing-slim` so that containers built on top of
it get newer community-maintained package releases than Debian stable offers.
It is published to Docker Hub as `kjake/base` for 386, amd64, arm64, arm/v7,
ppc64le, s390x and riscv64.

## Tags

| Tag          | Meaning                                                   |
|--------------|-----------------------------------------------------------|
| `latest`     | Most recent weekly rebuild of Debian testing.             |
| `YYYYMMDD`   | The rebuild from that day; pin this for reproducible builds. |

## What the image provides

- Apt sources for `testing`, `testing-updates` and `testing-security`, over
  https, with the `main`, `contrib`, `non-free` and `non-free-firmware`
  components enabled. See `debian.sources`.
- A fully upgraded package set plus `ca-certificates`, `locales`, `less`,
  `patch`, `diffutils`, `debconf-utils` and `vim-tiny` linked as `vim`.
- `DEBIAN_FRONTEND=noninteractive`, `LC_ALL=C.UTF-8` and `TERM=xterm`.
- `/app/lib/common.sh`, a small helper library for child images with `MSG`,
  `ERR`, `CHECK_BIN` and `CHECK_VAR`.
- An interactive `/etc/bash.bashrc` with the Chambana prompt.

## Building and testing

```sh
docker build -t kjake/base .
docker run --rm -v "$PWD/tests:/tests:ro" kjake/base bash /tests/smoke.sh
```

The build fails if any apt repository cannot be fetched. `tests/smoke.sh`
checks the apt configuration, installed tooling, environment and helper
library; set `SMOKE_OFFLINE=1` to skip the checks that need network access.

## CI

- **Docker**: weekly and on every push to `master`, builds and smoke tests
  the image, then builds all platforms and pushes `latest` and a dated tag.
- **Anchore Container Scan**: on pull requests, weekly and on push; lints the
  scripts and Dockerfile, builds and smoke tests the image, then scans it with
  Grype and uploads the results to code scanning.
- **Dependabot auto-merge**: merges Dependabot pull requests once the scan
  workflow succeeds.
- **Keepalive**: keeps scheduled workflows from being disabled by inactivity.
