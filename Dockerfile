FROM debian:testing-slim

LABEL maintainer="kjake" \
      org.opencontainers.image.title="kjake/base" \
      org.opencontainers.image.description="Debian testing base image with contrib and non-free enabled" \
      org.opencontainers.image.source="https://github.com/kjake/docker-base" \
      org.opencontainers.image.licenses="GPL-3.0"

ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive

# Configure Apt. This replaces the base image's deb822 source list; see the
# comments in debian.sources for why it starts out on http.
COPY debian.sources /etc/apt/sources.list.d/debian.sources

# Prepare environment. /app/lib/common.sh is kept for downstream images;
# bootstrap.sh removes itself once it has run.
COPY lib/common.sh /app/lib/common.sh
COPY --chmod=0755 bin/bootstrap.sh /app/bin/bootstrap.sh
RUN /app/bin/bootstrap.sh

# Install Chambana.net bashrc
COPY bashrc /etc/bash.bashrc

ENV LC_ALL=C.UTF-8
ENV TERM=xterm
