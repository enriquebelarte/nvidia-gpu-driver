ARG ARCH='x86_64'
ARG RHEL_VERSION=''
ARG KERNEL_VERSION=''
ARG BASE_DIGEST=''

FROM ghcr.io/smgglrs/driver-toolkit:${KERNEL_VERSION}.${ARCH} as builder

ARG ARCH='x86_64'
ARG DRIVER_VERSION=''
ARG DRIVER_EPOCH=''
ARG KERNEL_VERSION=''
ARG RHEL_VERSION=''

WORKDIR /home/builder
COPY --chown=1001:0 x509-configuration.ini x509-configuration.ini

RUN export KVER=$(echo ${KERNEL_VERSION} | cut -d '-' -f 1) \
        KREL=$(echo ${KERNEL_VERSION} | cut -d '-' -f 2 | sed 's/\.el._.$//') \
        KDIST=$(echo ${KERNEL_VERSION} | cut -d '-' -f 2 | sed 's/^.*\(\.el._.\)$/\1/') \
        DRIVER_STREAM=$(echo ${DRIVER_VERSION} | cut -d '.' -f 1) \
    && curl -sLO https://us.download.nvidia.com/tesla/${DRIVER_VERSION}/NVIDIA-Linux-${ARCH}-${DRIVER_VERSION}.run \
    && git clone -b rhel8 https://github.com/NVIDIA/yum-packaging-precompiled-kmod \
    && cd yum-packaging-precompiled-kmod \
    && mkdir BUILD BUILDROOT RPMS SRPMS SOURCES SPECS \
    && mkdir nvidia-kmod-${DRIVER_VERSION}-${ARCH} \
    && sh ${HOME}/NVIDIA-Linux-${ARCH}-${DRIVER_VERSION}.run --extract-only --target tmp \
    && mv tmp/kernel nvidia-kmod-${DRIVER_VERSION}-${ARCH}/ \
    && tar -cJf SOURCES/nvidia-kmod-${DRIVER_VERSION}-${ARCH}.tar.xz nvidia-kmod-${DRIVER_VERSION}-${ARCH} \
    && mv kmod-nvidia.spec SPECS/ \
    && sed -i -e 's/\$USER/builder/' -e 's/\$EMAIL/builder@smgglrs.io/' ${HOME}/x509-configuration.ini \
    && openssl req -x509 -new -nodes -utf8 -sha256 -days 36500 -batch \
      -config ${HOME}/x509-configuration.ini \
      -outform DER -out SOURCES/public_key.der \
      -keyout SOURCES/private_key.priv \
    && rpmbuild \
        --define "%_topdir $(pwd)" \
        --define "debug_package %{nil}" \
        --define "kernel ${KVER}" \
        --define "kernel_release ${KREL}" \
        --define "kernel_dist ${KDIST}" \
        --define "driver ${DRIVER_VERSION}" \
        --define "epoch ${DRIVER_EPOCH}" \
        --define "driver_branch ${DRIVER_STREAM}" \
        -v -bb SPECS/kmod-nvidia.spec


FROM registry.access.redhat.com/ubi8/ubi@${BASE_DIGEST}

USER root

ARG ARCH='x86_64'

ARG DRIVER_TYPE='passthrough'
ARG DRIVER_VERSION=''
ARG DRIVER_EPOCH='1'
ARG CUDA_VERSION=''
ARG KERNEL_VERSION=''
ARG RHEL_VERSION=''
ARG BASE_DIGEST=''

COPY --from=builder /home/builder/yum-packaging-precompiled-kmod/RPMS/${ARCH}/*.rpm /rpms/
COPY ./rhsm-register /usr/local/bin/rhsm-register

RUN --mount=type=secret,id=RHSM_ORG \
    --mount=type=secret,id=RHSM_ACTIVATIONKEY \
    rm /etc/rhsm-host \
    && /usr/local/bin/rhsm-register \
    && subscription-manager repos \
        --enable rhel-8-for-${ARCH}-baseos-rpms \
        --enable rhel-8-for-${ARCH}-appstream-rpms \
    && echo "${RHEL_VERSION}" > /etc/dnf/vars/releasever \
    && dnf config-manager --best --nodocs --setopt=install_weak_deps=False --save \
    && dnf config-manager --add-repo=http://developer.download.nvidia.com/compute/cuda/repos/rhel8/${ARCH}/cuda-rhel8.repo \
    && rpm --import http://developer.download.nvidia.com/compute/cuda/repos/rhel8/${ARCH}/7fa2af80.pub \
    && VERSION_ARRAY=(${DRIVER_VERSION//./ }) \
    && if [ "$DRIVER_TYPE" != "vgpu" ] ; then \
        if [ ${VERSION_ARRAY[0]} -ge 470 ] || ([ ${VERSION_ARRAY[0]} == 460 ] && [ ${VERSION_ARRAY[1]} -ge 91 ]) ; then \
            FABRIC_MANAGER_PKG=nvidia-fabric-manager-${DRIVER_VERSION}-1 ; \
        else \
            FABRIC_MANAGER_PKG=nvidia-fabric-manager-${VERSION_ARRY[0]}-${DRIVER_VERSION}-1 ; \
        fi ; \
        NSCQ_PKG=libnvidia-nscq-${VERSION_ARRAY[0]}-${DRIVER_VERSION}-1 ; \
    fi \
    && dnf -y module enable nvidia-driver:${VERSION_ARRAY[0]}/fm \
    && dnf -y install kmod \
    && mkdir -p /lib/modules/${KERNEL_VERSION}.${ARCH} \
    && touch /lib/modules/${KERNEL_VERSION}.${ARCH}/modules.order \
    && touch /lib/modules/${KERNEL_VERSION}.${ARCH}/modules.builtin \
    && dnf -y install \
        /rpms/kmod-nvidia-*.rpm \
        cuda-compat-${CUDA_VERSION}-${DRIVER_VERSION} \
        cuda-cudart-${CUDA_VERSION} \
        nvidia-driver-cuda-${DRIVER_VERSION} \
	nvidia-driver-libs-${DRIVER_VERSION} \
	nvidia-driver-NVML-${DRIVER_VERSION} \
        ${FABRIC_MANAGER_PKG} \
        ${NSCQ_PKG} \
     && mkdir -p /opt/lib/modules \
     && mv /lib/modules/${KERNEL_VERSION}.${ARCH} /opt/lib/modules \
     && dnf clean all \
     && subscription-manager unregister \
     && rm -rf /rpms

USER 1001

LABEL io.k8s.description="NVIDIA GPU Driver allows deploying matching driver / kernel versions on Kubernetes" \
      io.k8s.display-name="NVIDIA GPU Driver" \
      io.openshift.release.operator=true \
      org.opencontainers.image.base.name="registry.access.redhat.com/ubi8/ubi:${RHEL_VERSION}" \
      org.opencontainers.image.base.digest="${BASE_DIGEST}" \
      org.opencontainers.image.source="https://github.com/smgglrs/nvidia-gpu-driver" \
      org.opencontainers.image.vendor="Smgglrs" \
      org.opencontainers.image.title="NVIDIA GPU Driver" \
      org.opencontainers.image.description="NVIDIA GPU Driver allows deploying matching driver / kernel versions on Kubernetes" \
      maintainer="Smgglrs" \
      name="nvidia-gpu-driver" \
      vendor="Smgglrs" \
      version="${DRIVER_VERSION}-${KERNEL_VERSION}.${ARCH}"

COPY ./nvidia-driver /usr/local/bin/nvidia-driver

ENTRYPOINT ["/usr/local/bin/nvidia-driver", "start"]