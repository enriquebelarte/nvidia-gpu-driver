#!/bin/sh
PATH_MOD=open-gpu-kernel-modules/kernel-open
PATH_KEY=/etc/pki/tls
openssl req -x509 -new -nodes -utf8 -sha256 -days 36500 -batch \
      -config x509-configuration.ini \
      -outform DER -out $PATH_KEY/public_key.der \
      -keyout $PATH_KEY/private/private_key.priv
modules=("nvidia-drm","nvidia","nvidia-modeset","nvidia-peermem","nvidia-uvm")
for MODULE in ${modules[@]}; do
/usr/src/kernels/$(uname -r)/scripts/sign-file \
          sha256 \
	  $PATH_KEY/private/private_key.priv \
          $PATH_KEY/public_key.der \
          $PATH_MOD/$MODULE.ko
done
