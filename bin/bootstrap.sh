#!/bin/bash
#
# Preparation script based on https://github.com/olberger/baseimage-docker
#

set -o errexit -o pipefail

# shellcheck source=lib/common.sh disable=SC1091
. /app/lib/common.sh

APT_INSTALL='apt-get install -y --no-install-recommends'
SOURCES=/etc/apt/sources.list.d/debian.sources

## Fail the build if any configured repository cannot be fetched, instead of
## silently continuing with missing or stale package lists.
apt_update() {
  apt-get -qq update --error-on=any
}

MSG "Updating apt repositories..."
apt_update

## Temporarily disable dpkg fsync to make building faster.
echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/02apt-speedup

## Prevent initramfs updates from trying to run grub and lilo.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189
export INITRD=no
mkdir -p /etc/container_environment
echo -n no > /etc/container_environment/INITRD

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

MSG "Installing packages..."
$APT_INSTALL apt-utils
$APT_INSTALL ca-certificates diffutils patch locales debconf-utils vim-tiny less

## Now that ca-certificates is present, fetch packages over https.
MSG "Switching apt repositories to https..."
sed -i 's|http://deb.debian.org/|https://deb.debian.org/|' "$SOURCES"
apt_update

## Link vim -> vim.tiny
ln -sf /usr/bin/vim.tiny /usr/bin/vim

## Fix locale.
dpkg-reconfigure locales && locale-gen C.UTF-8 && /usr/sbin/update-locale LANG=C.UTF-8

MSG "Upgrading all packages..."
apt-get dist-upgrade -y --no-install-recommends

MSG "Cleaning up after build..."
apt-get clean
rm -rf /build
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup

## Remove self
rm -f /app/bin/bootstrap.sh
