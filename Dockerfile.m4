m4_changequote([[, ]])

##################################################
## "build" stage
##################################################

m4_ifdef([[CROSS_ARCH]], [[FROM docker.io/CROSS_ARCH/ubuntu:18.04]], [[FROM docker.io/ubuntu:18.04]]) AS build
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
		tzdata

# Build GoAccess
ARG GOACCESS_TREEISH=v1.4
ARG GOACCESS_REMOTE=https://github.com/allinurl/goaccess.git
RUN mkdir /tmp/goaccess/
WORKDIR /tmp/goaccess/
RUN git clone "${GOACCESS_REMOTE:?}" ./
RUN git checkout "${GOACCESS_TREEISH:?}"
RUN git submodule update --init --recursive
RUN autoreconf -fiv
RUN ./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-utf8=yes \
		--enable-geoip=mmdb \
		--with-getline=yes \
		--with-openssl=yes
RUN make -j"$(nproc)"
RUN checkinstall --default \
		--pkgname=goaccess \
		--pkgversion=0 --pkgrelease=0 \
		--exclude=/usr/include/,/usr/lib/pkgconfig/,/usr/share/man/ --nodoc \
		make install
RUN file /usr/bin/goaccess
RUN /usr/bin/goaccess --version

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
		libmaxminddb0 \
		libncursesw5 \
		libssl1.1 \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Install GoAccess from package
COPY --from=build --chown=root:root /tmp/goaccess/goaccess_*.deb /tmp/
RUN dpkg -i /tmp/goaccess_*.deb && rm -f /tmp/goaccess_*.deb

# Copy GoAccess config
COPY --chown=root:root ./config/goaccess/ /etc/goaccess/

# Download GeoIP2 database
RUN GEOIP2_DB_PAGE_URL='https://db-ip.com/db/download/ip-to-city-lite' \
	GEOIP2_DB_PAGE_REGEX='https://download\.db-ip\.com/free/dbip-city-lite-[0-9]{4}-[0-9]{2}\.mmdb\.gz' \
	GEOIP2_DB_URL=$(curl -fsSL "${GEOIP2_DB_PAGE_URL:?}" | grep -Eo "${GEOIP2_DB_PAGE_REGEX:?}") \
	&& mkdir /var/lib/GeoIP/ && curl -L "${GEOIP2_DB_URL:?}" | gunzip > /var/lib/GeoIP/GeoLite2-City.mmdb

# WebSocket port
EXPOSE 7890/tcp

ENTRYPOINT ["/usr/bin/goaccess"]
CMD ["--config-file=/etc/goaccess/goaccess.conf", "--browsers-file=/etc/goaccess/browsers.list", "--geoip-database=/var/lib/GeoIP/GeoLite2-City.mmdb"]
