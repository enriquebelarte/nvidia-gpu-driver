ARG ARCH='x86_64'
ARG RHEL_VERSION='9.2'
ARG KERNEL_VERSION='5.14.0-284.30.1'
ARG BASE_DIGEST=''
FROM quay.io/ebelarte/driver-toolkit:5.14.0-284.30.1.el9_2 as builder

ARG ARCH='x86_64'
ARG DRIVER_VERSION='535.104.05'
ARG DRIVER_EPOCH='1'
ARG KERNEL_VERSION='5.14.0-284.30.1.el9_2'
ARG RHEL_VERSION='9.2'
ARG KERNEL_SOURCES='/usr/src/kernels/${KERNEL_VERSION}.${ARCH}'
ARG KERNEL_OUTPUT='/usr/src/kernels/${KERNEL_VERSION}.${ARCH}'

WORKDIR /home/builder
COPY signer.sh signer.sh
COPY --chown=1001:0 x509-configuration.ini x509-configuration.ini

RUN export KVER=$(echo ${KERNEL_VERSION} | cut -d '-' -f 1) \
        KREL=$(echo ${KERNEL_VERSION} | cut -d '-' -f 2 | sed 's/\.el._.$//') \
        KDIST=$(echo ${KERNEL_VERSION} | cut -d '-' -f 2 | sed 's/^.*\(\.el._.\)$/\1/') \
        DRIVER_STREAM=$(echo ${DRIVER_VERSION} | cut -d '.' -f 1) \
        KSOURCES=$(echo ${KERNEL_VERSION}.${ARCH} \
    && sed -i -e 's/\$USER/builder/' -e 's/\$EMAIL/builder@smgglrs.io/' x509-configuration.ini \
    && git clone -b ${DRIVER_VERSION}  https://github.com/NVIDIA/open-gpu-kernel-modules.git \
    && cd open-gpu-kernel-modules \
    && make SYSSRC=${KERNEL_SOURCES} SYSOUT=${KERNEL_OUTPUT} modules \
    && cd .. && sh signer.sh


#FROM registry.access.redhat.com/ubi9/ubi:9.2
#FROM quay.io/ebelarte/ubi9:5.14.0-284.30.1.el9_2 
#USER root
#ARG ARCH='x86_64'
#ARG DRIVER_TYPE='passthrough'
#ARG DRIVER_VERSION='535.104.05'
#ARG DRIVER_EPOCH='1'
#ARG CUDA_VERSION='12-2'
#ARG CUDART_VERSION='12.2.140'
#ARG KERNEL_VERSION='5.14.0-284.30.1.el9_2'
#ARG RHEL_VERSION='9.2'
#ARG BASE_DIGEST=''
#
#COPY --from=builder /home/builder/yum-packaging-precompiled-kmod/RPMS/${ARCH}/*.rpm /rpms/
#
#
#RUN echo "${RHEL_VERSION}" > /etc/dnf/vars/releasever \
#    #&& subscription-manager repos --enable codeready-builder-for-rhel-9-${ARCH}-rpms \
#    #&& dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
#    && dnf config-manager --best --nodocs --setopt=install_weak_deps=False --save \
#    && dnf config-manager --add-repo=http://developer.download.nvidia.com/compute/cuda/repos/rhel9/${ARCH}/cuda-rhel9.repo \
#    && rpm --import http://developer.download.nvidia.com/compute/cuda/repos/rhel9/${ARCH}/D42D0685.pub \
#    && VERSION_ARRAY=(${DRIVER_VERSION//./ }) \
#    && if [ "$DRIVER_TYPE" != "vgpu" ] ; then \
#        if [[ ${VERSION_ARRAY[0]} -ge 470 ]] || ([[ ${VERSION_ARRAY[0]} == 460 && ${VERSION_ARRAY[1]} -ge 91 ]]) ; then \
#            FABRIC_MANAGER_PKG=nvidia-fabric-manager-${DRIVER_VERSION}-1 ; \
#        else \
#            FABRIC_MANAGER_PKG=nvidia-fabric-manager-${VERSION_ARRAY[0]}-${DRIVER_VERSION}-1 ; \
#        fi ; \
#        NSCQ_PKG=libnvidia-nscq-${VERSION_ARRAY[0]}-${DRIVER_VERSION}-1 ; \
#    fi \
#    && dnf -y module enable nvidia-driver:${VERSION_ARRAY[0]}-open/fm \
#    && mkdir -p /lib/modules/${KERNEL_VERSION}.${ARCH} \
#    && touch /lib/modules/${KERNEL_VERSION}.${ARCH}/modules.order \
#    && touch /lib/modules/${KERNEL_VERSION}.${ARCH}/modules.builtin \
#    && dnf -y install \
#        /rpms/kmod-nvidia-*.rpm \
#        cuda-compat-${CUDA_VERSION}-${DRIVER_VERSION} \
#        cuda-cudart-${CUDA_VERSION}-${CUDART_VERSION}-1 \
#        nvidia-driver-cuda-${DRIVER_VERSION} \
#	nvidia-driver-libs-${DRIVER_VERSION} \
#	nvidia-driver-NVML-${DRIVER_VERSION} \
#        ${FABRIC_MANAGER_PKG} \
#        ${NSCQ_PKG} \
#     && mkdir -p /opt/lib/modules \
#     && mv /lib/modules/${KERNEL_VERSION}.${ARCH} /opt/lib/modules \
#     && dnf clean all 
#
#USER 1001
#
#LABEL io.k8s.description="NVIDIA GPU Driver allows deploying matching driver / kernel versions on Kubernetes" \
#      io.k8s.display-name="NVIDIA GPU Driver" \
#      io.openshift.release.operator=true \
#      org.opencontainers.image.base.name="registry.access.redhat.com/ubi9/ubi:${RHEL_VERSION}" \
#      org.opencontainers.image.base.digest="${BASE_DIGEST}" \
#      org.opencontainers.image.source="https://github.com/enriquebelarte/nvidia-gpu-driver" \
#      org.opencontainers.image.vendor="enriquebelarte" \
#      org.opencontainers.image.title="NVIDIA GPU Driver" \
#      org.opencontainers.image.description="NVIDIA GPU Driver allows deploying matching driver / kernel versions on Kubernetes" \
#      maintainer="enriquebelarte" \
#      name="nvidia-gpu-driver" \
#      vendor="enriquebelarte" \
#      version="${DRIVER_VERSION}-${KERNEL_VERSION}.${ARCH}"
#
#COPY ./nvidia-driver /usr/local/bin/nvidia-driver
#
#ENTRYPOINT ["/usr/local/bin/nvidia-driver", "start"]
