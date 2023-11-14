# NVIDIA GPU Driver Container

This repository contains everything needed to build a container image with a
precompiled NVIDIA driver. It requires to know the kernel version, since it
builds and installs the driver package for a given kernel.

The image creation uses a multi-stage approach that leverages the
[driver-toolkit](https://github.com/smgglrs/driver-toolkit) container image to
build the driver package, then install the package in the final image, along
with NVIDIA CUDA dependencies.

It is inspired by NVIDIA blog article [Streamlining NVIDIA Driver Deployment on RHEL 8 with Modularity Streams](https://developer.nvidia.com/blog/streamlining-nvidia-driver-deployment-on-rhel-8-with-modularity-streams/).

## How to build a driver container

### Register to Red Hat

The first step is to create a Red Hat account at https://access.redhat.com.
Once connected, we're entitled to Red Hat Developer Subscription for
Individuals, which allows us to register up to 16 machines.

### Create an activation key

Instead of passing our credentials, we can use an activation key that
subscribes the system with Red Hat Subscription Manager and allows us to
install/update packages on the machine. To create the activation key, we open
https://access.redhat.com/management/activation_keys/new and fill the form:

* Name: `driver-toolkit-builder`
* Service Level: `Self Support`
* Auto Attach: `Enabled`
* Subcriptions: `Red Hat Developer Subscription for Individuals`

On the Activation Keys page, note the Organization ID, e.g. `12345678`.

Let's create two files to store the organization id and the activation key
name.

```
echo "12345678" > ${HOME}/.rhsm_org
echo "driver-toolkit-builder" > ${HOME}/.rhsm_activationkey
```

### Manual build of the container image

Below is an example for building a driver toolkit image for the version
`4.18.0-348.2.1.el8_5` of the kernel. We can see that we pass the Red Hat
organization id and the name of the activation key that we created above.

```shell
export RHEL_VERSION="8.4"
export KERNEL_VERSION="4.18.0-348.2.1.el8_5"
export DRIVER_VERSION="510.47.03"
export DRIVER_EPOCH="1"
export CUDA_VERSION="11-6"

podman build \
    --secret id=RHSM_ORG,src=${HOME}/.rhsm_org \
    --secret id=RHSM_ACTIVATIONKEY,src=${HOME}/.rhsm_activationkey \
    --build-arg ARCH=x86_64 \
    --build-arg RHEL_VERSION=${RHEL_VERSION} \
    --build-arg KERNEL_VERSION=${KERNEL_VERSION} \
    --build-arg DRIVER_VERSION=${DRIVER_VERSION} \
    --build-arg DRIVER_EPOCH=${DRIVER_EPOCH} \
    --build-arg CUDA_VERSION=${CUDA_VERSION} \
    --tag quay.io/smgglrs/nvidia-gpu-driver:${DRIVER_VERSION}-${KERNEL_VERSION} \
    --file Dockerfile .
```

The resulting container image is fairly smaller than the `driver-toolkit`
image, but still big at 700 MB, due to the CUDA dependencies installed.

For that image to be usable in our OpenShift clusters, we simply push it to
Quay.io.

```shell
podman login quay.io
podman push quay.io/smgglrs/nvidia-gpu-driver:${DRIVER_VERSION}-${KERNEL_VERSION}
```

## Maintain a library of NVIDIA GPU driver images

<mark>TODO</mark>
