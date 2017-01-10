# Lastet phusion baseimage as of 2016.11, based on ubuntu 16.04
# See https://hub.docker.com/r/phusion/baseimage/tags/
FROM phusion/baseimage:0.9.19

ENV UPDATED_AT=20161124 \
    DEBIAN_FRONTEND=noninteractive

CMD ["/sbin/my_init", "--", "bash", "-l"]

# Utility tools
RUN apt-get update -qq && apt-get install -qq -y vim htop net-tools psmisc git wget curl

# Guidline for installing python libs: if a lib has C-compoment (e.g.
# python-imaging depends on libjpeg/libpng), we install it use apt-get.
# Otherwise we install it with pip.
RUN apt-get install -y python2.7-dev python-imaging python-ldap python-mysqldb
RUN curl -sSL -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python /tmp/get-pip.py && \
    rm -rf /tmp/get-pip.py && \
    pip install -U wheel

ADD requirements.txt  /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# Clean up for docker squash
# See https://github.com/goldmann/docker-squash
RUN rm -rf \
    /root/.cache \
    /root/.npm \
    /root/.pip \
    /usr/local/share/doc \
    /usr/share/doc \
    /usr/share/man \
    /usr/share/vim/vim74/doc \
    /usr/share/vim/vim74/lang \
    /usr/share/vim/vim74/spell/en* \
    /usr/share/vim/vim74/tutor \
    /var/lib/apt/lists/* \
    /tmp/*

WORKDIR /opt/seafile

ENV SEAFILE_VERSION=6.0.7

# syslog-ng and syslog-forwarder would mess up the container stdout, not good
# when debugging/upgrading.
RUN sed -i -e 's|\(^exec syslog-ng.*$\)|\1 >>/var/log/syslog-ng.log 2>\&1|g' /etc/service/syslog-ng/run && \
    rm -rf /etc/service/syslog-forwarder

RUN mkdir -p /opt/seafile/ && \
    curl -sSL -o - https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz \
    | tar xzf - -C /opt/seafile/

RUN mkdir -p /etc/my_init.d
