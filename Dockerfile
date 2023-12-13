ARG ARCH='x86_64'
ARG RHEL_VERSION='9.3'
ARG KERNEL_VERSION='5.14.0-362.13.1'
ARG BASE_DIGEST=''
FROM quay.io/ebelarte/driver-toolkit:5.14.0-362.13.1.el9_3 as builder

ARG ARCH='x86_64'
ARG DRIVER_VERSION='535.104.05'
ARG DRIVER_EPOCH='1'
ARG KERNEL_VERSION='5.14.0-362.13.1.el9_3'
ARG RHEL_VERSION='9.3'
ARG KERNEL_SOURCES='/usr/src/kernels/${KERNEL_VERSION}.${ARCH}'
ARG KERNEL_OUTPUT='/usr/src/kernels/${KERNEL_VERSION}.${ARCH}'

WORKDIR /home/builder
COPY signer.sh signer.sh
COPY --chown=1001:0 x509-configuration.ini x509-configuration.ini

RUN export KVER=$(echo ${KERNEL_VERSION} | cut -d '-' -f 1) \
        KREL=$(echo ${KERNEL_VERSION} | cut -d '-' -f 2 | sed 's/\.el._.$//') \
        KDIST=$(echo ${KERNEL_VERSION} | cut -d '-' -f 2 | sed 's/^.*\(\.el._.\)$/\1/') \
        DRIVER_STREAM=$(echo ${DRIVER_VERSION} | cut -d '.' -f 1) \
        KSOURCES=$(echo ${KERNEL_VERSION}.${ARCH}) \
    && sed -i -e 's/\$USER/builder/' -e 's/\$EMAIL/builder@smgglrs.io/' x509-configuration.ini \
    && git clone -b ${DRIVER_VERSION}  https://github.com/NVIDIA/open-gpu-kernel-modules.git \
    && cd open-gpu-kernel-modules \
    && make SYSSRC=${KERNEL_SOURCES} SYSOUT=${KERNEL_OUTPUT} modules \
    && cd .. && sh signer.sh

