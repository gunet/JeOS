FROM debian:bullseye-slim

LABEL gr.gunet.uRescom.maintainer="info@gunet.gr"
LABEL org.opencontainers.image.source="https://github.com/gunet/JeOS"
LABEL org.opencontainers.image.description="GUNet Just enough OS"

ENV JEOS_DIR=/var/jeos

RUN apt-get update && apt-get install -yq \
    xorriso \
    syslinux \
    rsync \
    curl \
    genisoimage \
    syslinux-utils \ 
    cpio && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    mkdir -p ${JEOS_DIR}/gunet && \
    mkdir -p ${JEOS_DIR}/debian && \
    mkdir -p ${JEOS_DIR}/final

ARG DEBIAN_VERSION=11.8.0
ARG DEBIAN_REPO=https://cdimage.debian.org/mirror/cdimage/archive/${DEBIAN_VERSION}/amd64/iso-cd
ARG DEBIAN_ISO=debian-${DEBIAN_VERSION}-amd64-netinst.iso

RUN curl -L ${DEBIAN_REPO}/${DEBIAN_ISO} > ${JEOS_DIR}/debian/${DEBIAN_ISO}
COPY mkiso.sh helper_functions.sh ${JEOS_DIR}/
COPY gunet/ ${JEOS_DIR}/gunet/

RUN chmod 0755 ${JEOS_DIR}/mkiso.sh && \
    chmod 0755 ${JEOS_DIR}/gunet/*.sh

WORKDIR ${JEOS_DIR}

ENV TZ=Europe/Athens
ENV DEBIAN_ISO=${DEBIAN_ISO}

# Network settings which can be passed along in the command-line if DHCP does not return something
# NET_IP: CIDR format for the IP
# NET_GATEWAY: The gateway to setup
# NET_NAMESERVERS: a list of nameservers (separated by space)
# NET_HOSTNAME: The hostname
# NET_DOMAIN: The domain
#
# Actual working example:
# ENV NET_IP="195.134.100.24/24"
# ENV NET_GATEWAY="195.134.100.1"
# ENV NET_NAMESERVERS="8.8.8.8 4.4.4.4"
# ENV NET_HOSTNAME="sso.gunet.gr"
# ENV NET_DOMAIN="gunet.gr"

ENV NET_STATIC="no"
ENV NET_IP="notset"
ENV NET_GATEWAY="notset"
ENV NET_NAMESERVERS="notset"
ENV NET_HOSTNAME="notset"
ENV NET_DOMAIN="notset"

# We can accept the root password from the command-line as an environment
# variable

ENV ROOT_PASSWORD="notset"

ENTRYPOINT [ "/var/jeos/mkiso.sh" ]

CMD ["${DEBIAN_ISO}"]
