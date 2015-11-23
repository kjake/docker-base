FROM debian:jessie-backports

MAINTAINER Josh King <jking@chambana.net>

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Prepare environment
ADD lib/common.sh /opt/chambana/lib/common.sh
ADD bin/bootstrap.sh /opt/chambana/bin/bootstrap.sh
RUN chmod 0755 /opt/chambana/bin/bootstrap.sh
RUN /opt/chambana/bin/bootstrap.sh

# Install Chambana.net bashrc
ADD bashrc /etc/bash.bashrc

ENV LC_ALL C.UTF-8
