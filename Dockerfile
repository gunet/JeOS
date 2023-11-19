FROM debian:bullseye-slim

LABEL gr.gunet.uRescom.maintainer="info@gunet.gr"
LABEL org.opencontainers.image.source="https://github.com/gunet/JeOS"
LABEL org.opencontainers.image.description="GUNet Just enough OS"

ENV JEOS_DIR=/var/jeos

RUN apt-get update && apt-get install -yq --no-install-recommends \
    xorriso \
    syslinux && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    mkdir -p ${JEOS_DIR}/gunet

COPY mkiso.sh ${JEOS_DIR}/
COPY gunet/ ${JEOS_DIR}/gunet/

RUN chmod 0755 ${JEOS_DIR}/mkiso.sh && \
    chmod 0755 gunet/*.sh

WORKDIR ${JEOS_DIR}

ENV TZ=Europe/Athens

ENTRYPOINT [ "${JEOS_DIR}/mkiso.sh" ]