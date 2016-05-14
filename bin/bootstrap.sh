#!/bin/bash
#
# Preparation script based on https://github.com/olberger/baseimage-docker
#

. /app/lib/common.sh

APT_INSTALL='apt-get install -y --no-install-recommends'

MSG "Updating apt repositories..."
apt-get -qq update

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
$APT_INSTALL apt-transport-https locales debconf-utils vim-tiny less telnet

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
