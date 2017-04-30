FROM ubuntu:xenial

ARG QT=5.7.0
ARG QTM=5.7

# Upgrade packages on image
# Preparations for sshd and qt
RUN apt-get update -q && \
	DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        build-essential \
        ca-certificates \
        default-jdk \
        git \
        libglu1-mesa-dev \
        libfontconfig1 \
        libice6 \
        libsm6 \
        # libX11-xcb1 \
        libxext6 \
        libxrender1 \
        locales \
        openssh-client \
        openssh-server \
        p7zip \
        xvfb \
    && apt-get clean

#install Qt to /opt directory
ADD qt-installer-noninteractive.qs /tmp/qt/script.qs

ADD http://download.qt.io/official_releases/qt/${QTM}/${QT}/qt-opensource-linux-x64-${QT}.run /tmp/qt/installer.run

RUN chmod +x /tmp/qt/installer.run \
    && xvfb-run /tmp/qt/installer.run --script /tmp/qt/script.qs \
     | egrep -v '\[[0-9]+\] Warning: (Unsupported screen format)|((QPainter|QWidget))' \
    && rm -rf /tmp/qt

RUN echo /opt/qt/${QTM}/gcc_64/lib > /etc/ld.so.conf.d/qt-${QTM}.conf
RUN locale-gen en_US.UTF-8 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/qt/${QTM}/gcc_64/bin

RUN useradd -ms /bin/bash jenkins
RUN chown -R jenkins:jenkins /opt/qt

# configure ccache
ENV CCACHE_DIR=/mnt/ccache
ENV CCACHE_MAXSIZE=10G

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /mnt/ccache
RUN touch /mnt/ccache/placeholder
RUN chown -R jenkins:jenkins /mnt/ccache
VOLUME /mnt/ccache

USER jenkins
WORKDIR /home/jenkins