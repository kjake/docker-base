FROM debian:jessie-backports

MAINTAINER Josh King <jking@chambana.net>

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Prepare environment
ADD prepare.sh /prepare.sh
RUN chmod 0755 /prepare.sh
RUN /prepare.sh

# Install Chambana.net bashrc
ADD bashrc /etc/bash.bashrc

ENV LC_ALL C.UTF-8
