m4_changequote([[, ]])

m4_ifelse(m4_index(DEBIAN_IMAGE_NAME, [[rpi]]), [[-1]],
	[[m4_define([[IS_RASPIOS]], 0)]],
	[[m4_define([[IS_RASPIOS]], 1)]]
)

##################################################
## "base" stage
##################################################

FROM DEBIAN_IMAGE_NAME:DEBIAN_IMAGE_TAG AS base
m4_ifdef([[CROSS_QEMU]], [[COPY --from=docker.io/hectormolinero/qemu-user-static:latest CROSS_QEMU CROSS_QEMU]])

# Install base packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		locales \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# Setup locale
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN printf '%s\n' "${LANG:?} UTF-8" > /etc/locale.gen \
	&& localedef -c -i "${LANG%%.*}" -f UTF-8 "${LANG:?}" ||:

# Setup timezone
ENV TZ=UTC
RUN printf '%s\n' "${TZ:?}" > /etc/timezone \
	&& ln -snf "/usr/share/zoneinfo/${TZ:?}" /etc/localtime

##################################################
## "build-base" stage
##################################################

FROM base AS build-base

# Install build packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		file \
		git \
		jq \
		pkgconf \
		unzip \
		wget \
	&& rm -rf /var/lib/apt/lists/*

##################################################
## "build-python" stage
##################################################

FROM build-base AS build-python

# Install Python
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		python3 \
		python3-dev \
		python3-venv \
	&& rm -rf /var/lib/apt/lists/*

ENV PIP_NO_CACHE_DIR=0
m4_ifelse(IS_RASPIOS, 1, [[ENV PIP_EXTRA_INDEX_URL=https://www.piwheels.org/simple]])

RUN python3 --version

##################################################
## "build-golang" stage
##################################################

FROM build-base AS build-golang

# Install Go
ENV GOROOT=/usr/local/go/ GOPATH=/go/
RUN mkdir -p "${GOROOT:?}" "${GOPATH:?}/bin" "${GOPATH:?}/src"
RUN GOLANG_VERSION=$(wget -qO- 'https://golang.org/dl/?mode=json' | jq -r 'map(select(.version | startswith("go1."))) | first | .version') \
	&& case "$(uname -m)" in x86_64) GOLANG_ARCH=amd64 ;; aarch64) GOLANG_ARCH=arm64 ;; armv6l|armv7l) GOLANG_ARCH=armv6l ;; esac \
	&& GOLANG_PKG_URL=https://dl.google.com/go/${GOLANG_VERSION:?}.linux-${GOLANG_ARCH:?}.tar.gz \
	&& wget -qO- "${GOLANG_PKG_URL:?}" | tar -xz --strip-components=1 -C "${GOROOT:?}"

ENV GO111MODULE=on
ENV CGO_ENABLED=1
ENV PATH=${GOROOT}/bin:${GOPATH}/bin:${PATH}

RUN go version

##################################################
## "build-bettercap" stage
##################################################

FROM build-golang AS build-bettercap

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		libnetfilter-queue-dev \
		libpcap-dev \
		libusb-1.0-0-dev \
	&& rm -rf /var/lib/apt/lists/*

# Build Bettercap
ARG BETTERCAP_TREEISH=v2.29
ARG BETTERCAP_REMOTE=https://github.com/bettercap/bettercap.git
RUN mkdir /tmp/bettercap/
WORKDIR /tmp/bettercap/
RUN git clone "${BETTERCAP_REMOTE:?}" ./
RUN git checkout "${BETTERCAP_TREEISH:?}"
RUN git submodule update --init --recursive
RUN go build -o ./dist/bettercap ./
RUN mv ./dist/bettercap /usr/bin/bettercap
RUN file /usr/bin/bettercap
RUN /usr/bin/bettercap --version

# Install Bettercap UI
ARG BETTERCAP_UI_VERSION=v1.3.0
ARG BETTERCAP_UI_PKG_URL=https://github.com/bettercap/ui/releases/download/${BETTERCAP_UI_VERSION}/ui.zip
RUN mkdir /tmp/bettercap-ui/
WORKDIR /tmp/bettercap-ui/
RUN wget -qO ./ui.zip "${BETTERCAP_UI_PKG_URL:?}"
RUN unzip -q ./ui.zip -d ./
RUN mkdir -p /usr/local/share/bettercap/
RUN mv ./ui/ /usr/local/share/bettercap/ui/

##################################################
## "build-pwngrid" stage
##################################################

FROM build-golang AS build-pwngrid

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		libpcap-dev \
	&& rm -rf /var/lib/apt/lists/*

# Build PwnGRID
ARG PWNGRID_TREEISH=v1.10.3
ARG PWNGRID_REMOTE=https://github.com/evilsocket/pwngrid.git
RUN mkdir /tmp/pwngrid/
WORKDIR /tmp/pwngrid/
RUN git clone "${PWNGRID_REMOTE:?}" ./
RUN git checkout "${PWNGRID_TREEISH:?}"
RUN git submodule update --init --recursive
RUN go build -o ./dist/pwngrid ./cmd/pwngrid/*.go
RUN mv ./dist/pwngrid /usr/bin/pwngrid
RUN file /usr/bin/pwngrid
RUN /usr/bin/pwngrid --version

##################################################
## "build-pwnagotchi" stage
##################################################

FROM build-python AS build-pwnagotchi

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		fonts-dejavu \
		gfortran \
		libaec-dev \
		libarchive-dev \
		libatlas-base-dev \
		libavcodec-dev \
		libavformat-dev \
		libavresample-dev \
		libavutil-dev \
		libbz2-dev \
		libevent-dev \
		libfreetype6-dev \
		libfuse-dev \
		libgstreamer-plugins-base1.0-dev \
		libgstreamer1.0-dev \
		libgtk-3-dev \
		libhdf5-dev \
		libhwloc-dev \
		libice-dev \
		libjbig-dev \
		libjpeg62-turbo-dev \
		liblcms2-dev \
		libltdl-dev \
		libopenexr-dev \
		libopenjp2-7-dev \
		libopenmpi-dev \
		libpng-dev \
		libqt4-dev \
		libqt4-opengl-dev \
		libsm-dev \
		libssl-dev \
		libswresample-dev \
		libswscale-dev \
		libtiff-dev \
		libvpx-dev \
		libwebp-dev \
		libzstd-dev \
		m4_ifelse(IS_RASPIOS, 1, [[libjasper-dev]]) \
	&& rm -rf /var/lib/apt/lists/*

# Build Pwnagotchi
ARG PWNAGOTCHI_TREEISH=5ec621c5d7e4893e2259d3861034da9c748da25f
ARG PWNAGOTCHI_REMOTE=https://github.com/evilsocket/pwnagotchi.git
RUN mkdir /tmp/pwnagotchi/
WORKDIR /tmp/pwnagotchi/
RUN git clone "${PWNAGOTCHI_REMOTE:?}" ./
RUN git checkout "${PWNAGOTCHI_TREEISH:?}"
RUN git submodule update --init --recursive
# Modify some hardcoded paths
RUN sed -ri 's|^\s*(DefaultPath)\s*=.+$|\1 = "/root/"|' ./pwnagotchi/identity.py
# Fix dependency constraint mismatch (https://github.com/piwheels/packages/issues/66)
m4_ifelse(IS_RASPIOS, 0, [[RUN sed -ri 's/^(tensorflow-estimator)==.*$/\1==1.13.0/' ./requirements.txt]])
# Enable "rpi" optional feature in the "inky" module
m4_ifelse(IS_RASPIOS, 1, [[RUN sed -ri 's/^(inky)==(.*)$/\1[rpi]==\2/' ./requirements.txt]])
# Create virtual environment and install requirements
ENV PWNAGOTCHI_VENV=/usr/lib/pwnagotchi/
ENV PWNAGOTCHI_ENABLE_INSTALLER=false
RUN python3 -m venv "${PWNAGOTCHI_VENV:?}"
RUN "${PWNAGOTCHI_VENV:?}"/bin/pip install --prefer-binary -r ./requirements.txt
RUN "${PWNAGOTCHI_VENV:?}"/bin/pip install ./
RUN "${PWNAGOTCHI_VENV:?}"/bin/pwnagotchi --version

##################################################
## "pwnagotchi" stage
##################################################

FROM base AS pwnagotchi

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		fbi \
		fonts-dejavu \
		gawk \
		gettext-base \
		iproute2 \
		iw \
		libaec0 \
		libarchive13 \
		libatlas3-base \
		libavcodec58 \
		libavformat58 \
		libavresample4 \
		libavutil56 \
		libbz2-1.0 \
		libevent-2.1-6 \
		libevent-pthreads-2.1-6 \
		libfreetype6 \
		libfuse2 \
		libgfortran5 \
		libgstreamer-plugins-base1.0-0 \
		libgstreamer1.0-0 \
		libgtk-3-0 \
		libhdf5-103 \
		libhwloc5 \
		libice6 \
		libjbig0 \
		libjpeg62-turbo \
		liblcms2-2 \
		libltdl7 \
		libnetfilter-queue1 \
		libopenexr23 \
		libopenjp2-7 \
		libopenmpi3 \
		libpcap0.8 \
		libpng16-16 \
		libqt4-opengl \
		libqt4-test \
		libqtcore4 \
		libsm6 \
		libssl1.1 \
		libswresample3 \
		libswscale5 \
		libsz2 \
		libtiff5 \
		libusb-1.0-0 \
		libvpx5 \
		libwebp6 \
		libwebpdemux2 \
		libwebpmux3 \
		libzstd1 \
		nano \
		net-tools \
		netcat-openbsd \
		openmpi-bin \
		python3 \
		python3-distutils \
		systemd \
		tcpdump \
		wireless-tools \
		m4_ifelse(IS_RASPIOS, 1, [[libjasper1]]) \
	&& rm -rf /var/lib/apt/lists/*

# Remove default systemd unit dependencies
RUN find \
		/lib/systemd/system/*.target.wants/ \
		/etc/systemd/system/*.target.wants/ \
		-not -name 'systemd-tmpfiles-setup.service' \
		-not -name 'systemd-journal*' \
		-mindepth 1 -print -delete

# Copy systemd config
COPY --chown=root:root ./config/systemd/ /etc/systemd/

# Copy Bettercap build
COPY --from=build-bettercap --chown=root:root /usr/bin/bettercap /usr/bin/bettercap
COPY --from=build-bettercap --chown=root:root /usr/local/share/bettercap/ /usr/local/share/bettercap/

# Copy Bettercap caplets
COPY --chown=root:root ./config/bettercap/caplets/ /usr/local/share/bettercap/caplets/

# Copy PwnGRID build
COPY --from=build-pwngrid --chown=root:root /usr/bin/pwngrid /usr/bin/pwngrid

# Copy Pwnagotchi build
COPY --from=build-pwnagotchi --chown=root:root /usr/lib/pwnagotchi/ /usr/lib/pwnagotchi/
RUN ln -s /usr/lib/pwnagotchi/bin/pwnagotchi /usr/bin/pwnagotchi

# Copy Pwnagotchi config
COPY --chown=root:root ./config/pwnagotchi/ /etc/pwnagotchi/

# Copy scripts
COPY --chown=root:root ./scripts/bin/ /usr/bin/

# Copy and enable services
COPY --chown=root:root ./scripts/service/ /etc/systemd/system/
RUN chmod 644 /etc/systemd/system/*.target /etc/systemd/system/*.service
RUN systemctl set-default container.target
RUN systemctl enable bettercap.service pwnagotchi.service pwngrid.service

# Environment
ENV PWNAGOTCHI_NAME=pwnagotchi
ENV PWNAGOTCHI_LANG=en
ENV PWNAGOTCHI_USERNAME=pwnagotchi
ENV PWNAGOTCHI_PASSWORD=pwnagotchi
ENV PWNAGOTCHI_IFACE_NET=phy0
ENV PWNAGOTCHI_IFACE_MON=mon0
ENV PWNAGOTCHI_IFACE_USB=usb0
ENV PWNAGOTCHI_MAX_BLIND_EPOCHS=10
ENV PWNAGOTCHI_WHITELIST=[]
ENV PWNAGOTCHI_FILTER=
ENV PWNAGOTCHI_WEB_ENABLED=true
ENV PWNAGOTCHI_WEB_ADDRESS=0.0.0.0
ENV PWNAGOTCHI_DISPLAY_ENABLED=true
ENV PWNAGOTCHI_DISPLAY_ROTATION=180
ENV PWNAGOTCHI_DISPLAY_TYPE=waveshare_2
ENV PWNAGOTCHI_PLUGIN_GRID_ENABLED=true
ENV PWNAGOTCHI_PLUGIN_GRID_REPORT=true
ENV PWNAGOTCHI_PLUGIN_GRID_EXCLUDE=[]
ENV PWNAGOTCHI_PLUGIN_LED_ENABLED=true
ENV PWNAGOTCHI_PLUGIN_MEMTEMP_ENABLED=true
ENV PWNAGOTCHI_PLUGIN_SESSION_STATS_ENABLED=true
ENV PWNAGOTCHI_PERSONALITY_ADVERTISE=true
ENV PWNAGOTCHI_PERSONALITY_DEAUTH=true
ENV PWNAGOTCHI_PERSONALITY_ASSOCIATE=true
ENV PWNAGOTCHI_PERSONALITY_CHANNELS=[]

HEALTHCHECK --start-period=30s --interval=10s --timeout=5s --retries=1 \
CMD ["/usr/bin/container-healthcheck-cmd"]

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/usr/bin/container-entrypoint-cmd"]
