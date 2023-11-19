FROM debian:bullseye-slim

LABEL gr.gunet.uRescom.maintainer="info@gunet.gr"
LABEL org.opencontainers.image.source="https://github.com/gunet/JeOS"
LABEL org.opencontainers.image.description="GUNet Just enough OS"

ENV JEOS_DIR=/var/jeos

RUN apt-get update && apt-get install -yq --no-install-recommends \
    xorriso \
    syslinux \
    rsync \
    genisoimage \
    syslinux-utils \ 
    cpio && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    mkdir -p ${JEOS_DIR}/gunet && \
    mkdir -p ${JEOS_DIR}/debian && \
    mkdir -p ${JEOS_DIR}/final

ENV DEBIAN_ISO=debian-11.8.0-amd64-netinst.iso

COPY debian/${DEBIAN_ISO} ${JEOS_DIR}/debian/
COPY mkiso.sh ${JEOS_DIR}/
COPY gunet/ ${JEOS_DIR}/gunet/

RUN chmod 0755 ${JEOS_DIR}/mkiso.sh && \
    chmod 0755 ${JEOS_DIR}/gunet/*.sh

WORKDIR ${JEOS_DIR}


ENV TZ=Europe/Athens

ENTRYPOINT [ "/var/jeos/mkiso.sh" ]