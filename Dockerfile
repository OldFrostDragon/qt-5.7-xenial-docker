FROM ubuntu:xenial

ARG QT=5.7.0
ARG QTM=5.7

# Upgrade packages on image
# Preparations for sshd and qt
RUN apt-get update -q && \
	DEBIAN_FRONTEND=noninteractive apt-get install -q -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        clang \
        clang-tidy-3.8 \
        clang-format-3.8 \
        cmake \
        dbus \
        # default-jdk \
        git \
        libclang-3.8-dev \
        # for qt installer
        libdbus-1-3 \
        libglu1-mesa-dev \
        # for qt installer
        libglib2.0-0 \
        libfontconfig1 \
        libice6 \
        libsm6 \
        libxext6 \
        libxrender1 \
        llvm \
        llvm-dev \
        locales \
        openssh-client \
        openssh-server \
        p7zip \
        subversion \
        xvfb \
        zlib1g-dev \
        # for web engine
        "^libxcb.*" \
        libasound2-dev \
        libdrm-dev \
        libicu-dev \
        libnss3-dev \
        libxcomposite-dev \
        libxcursor-dev \
        libxslt-dev \
        libxtst-dev \
        libglu1-mesa-dev \
        libx11-xcb-dev \
        libxi-dev \
        libxrender-dev \
    && apt-get clean

RUN dbus-uuidgen > /var/lib/dbus/machine-id

#install Qt to /opt directory
ADD qt-installer-noninteractive.qs /tmp/qt/script.qs

ADD http://download.qt.io/official_releases/qt/${QTM}/${QT}/qt-opensource-linux-x64-${QT}.run /tmp/qt/installer.run

RUN chmod +x /tmp/qt/installer.run \
    && xvfb-run --server-args="-screen 0, 1024x768x24" /tmp/qt/installer.run -v --script /tmp/qt/script.qs \
    | egrep -v '\[[0-9]+\] Warning: (Unsupported screen format)|((QPainter|QWidget))' \
    && rm -rf /tmp/qt

RUN echo /opt/qt/${QTM}/gcc_64/lib > /etc/ld.so.conf.d/qt-${QTM}.conf

RUN locale-gen en_US.UTF-8 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/qt/${QTM}/gcc_64/bin

# build and install bear for to allow compilation database generation
RUN mkdir /tmp/bear && \
    cd /tmp/bear && \
    git clone --branch 2.3.4 https://github.com/rizsotto/Bear.git . && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf /tmp/bear

# build and install clazy
RUN mkdir /tmp/clazy && \
    cd /tmp/clazy && \
    git clone --branch v1.1 https://github.com/KDE/clazy.git . && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release && \
    make -j4 && \
    make install && \
    cd ../.. && \
    rm -rf /tmp/clazy

RUN useradd -ms /bin/bash jenkins && \
    chown -R jenkins:jenkins /opt/qt

# configure ccache
ENV CCACHE_DIR=/mnt/ccache
ENV CCACHE_MAXSIZE=10G

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /mnt/ccache && \
    touch /mnt/ccache/placeholder && \
    chown -R jenkins:jenkins /mnt/ccache

VOLUME /mnt/ccache

USER jenkins
WORKDIR /home/jenkins

EXPOSE 80