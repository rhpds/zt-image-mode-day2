#!/bin/bash


## Convert the system to Image Mode
# system-reinstall-bootc quay.io/toharris/rhel-bootc:summit-2025
# Found only one user (root) with 1 SSH authorized keys.
# Would you like to import its SSH authorized keys
# into the root user on the new bootc system? yes

# Going to run command "podman" "run" "--privileged" "--pid=host" "--user=root:root" "-v" "/var/lib/containers:/var/lib/containers" "-v" "/dev:/dev" "--security-opt" "label=type:unconfined_t" "-v" "/:/target" "-v" "/tmp/.tmp08wosc:/bootc_authorized_ssh_keys/root" "quay.io/toharris/rhel-bootc:summit-2025" "bootc" "install" "to-existing-root" "--acknowledge-destructive" "--root-ssh-authorized-keys" "/bootc_authorized_ssh_keys/root"
# podman run --rm --privileged -v /dev:/dev -v /var/lib/containers:/var/lib/containers -v /:/target --pid=host --security-opt label=type:unconfined_t quay.io/toharris/rhel-bootc:summit-2025 bootc install to-existing-root --root-ssh-authorized-keys /target/root/.ssh/authorized_keys --acknowledge-destructive
podman run --privileged --pid=host --user=root:root -v /var/lib/containers:/var/lib/containers -v /dev:/dev --security-opt label=type:unconfined_t -v /:/target -v /tmp/.tmp08wosc:/bootc_authorized_ssh_keys/root quay.io/toharris/rhel-bootc:summit-2025 bootc install to-existing-root --acknowledge-destructive --root-ssh-authorized-keys /bootc_authorized_ssh_keys/root

echo "DONE" >> /root/job.log
