#!/bin/bash


## Convert the system to Image Mode
podman run --rm --privileged -v /dev:/dev -v /var/lib/containers:/var/lib/containers -v /:/target --pid=host --security-opt label=type:unconfined_t quay.io/toharris/rhel-bootc:summit-2025 bootc install to-existing-root --root-ssh-authorized-keys /target/root/.ssh/authorized_keys --acknowledge-destructive

