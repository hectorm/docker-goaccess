m4_changequote([[, ]])

##################################################
## "build-goaccess" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:18.04]], [[FROM docker.io/ubuntu:18.04]]) AS build-goaccess
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		autopoint \
		build-essential \
		ca-certificates \
		checkinstall \
		file \
		gawk \
		gettext \
		git \
		libmaxminddb-dev \
		libncursesw5-dev \
		libssl-dev \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Build GoAccess
ARG GOACCESS_TREEISH=v1.3
ARG GOACCESS_REMOTE=https://github.com/allinurl/goaccess.git
RUN mkdir -p /tmp/goaccess/ && cd /tmp/goaccess/ \
	&& git clone "${GOACCESS_REMOTE:?}" ./ \
	&& git checkout "${GOACCESS_TREEISH:?}" \
	&& git submodule update --init --recursive
RUN cd /tmp/goaccess/ \
	&& autoreconf -fiv \
	&& ./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-utf8=yes \
		--enable-geoip=mmdb \
		--enable-tcb=no \
		--with-getline=yes \
		--with-openssl=yes \
	&& make -j"$(nproc)" \
	&& checkinstall --default \
		--pkgname=goaccess \
		--pkgversion=0 --pkgrelease=0 \
		--exclude=/usr/include/,/usr/lib/pkgconfig/,/usr/share/man/ --nodoc \
		make install \
	&& file /usr/bin/goaccess && /usr/bin/goaccess --version

##################################################
## "goaccess" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:18.04]], [[FROM docker.io/ubuntu:18.04]]) AS goaccess
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Environment
ENV TERM=xterm-256color

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		geoipupdate \
		libmaxminddb0 \
		libncursesw5 \
		libssl1.1 \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Install GoAccess from package
COPY --from=build-goaccess --chown=root:root /tmp/goaccess/goaccess_*.deb /tmp/
RUN dpkg -i /tmp/goaccess_*.deb && rm /tmp/goaccess_*.deb

# Copy GoAccess config
COPY --chown=root:root config/goaccess/ /etc/goaccess/

# Update GeoIP2 database
RUN geoipupdate -v

# WebSocket port
EXPOSE 7890/tcp

ENTRYPOINT ["/usr/bin/goaccess"]
CMD ["--config-file=/etc/goaccess/goaccess.conf", "--browsers-file=/etc/goaccess/browsers.list"]
