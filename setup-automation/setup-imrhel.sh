#!/bin/bash


## Convert the system to Image Mode
# system-reinstall-bootc quay.io/toharris/rhel-bootc:summit-2025
# Found only one user (root) with 1 SSH authorized keys.
# Would you like to import its SSH authorized keys
# into the root user on the new bootc system? yes

# Going to run command "podman" "run" "--privileged" "--pid=host" "--user=root:root" "-v" "/var/lib/containers:/var/lib/containers" "-v" "/dev:/dev" "--security-opt" "label=type:unconfined_t" "-v" "/:/target" "-v" "/tmp/.tmp08wosc:/bootc_authorized_ssh_keys/root" "quay.io/toharris/rhel-bootc:summit-2025" "bootc" "install" "to-existing-root" "--acknowledge-destructive" "--root-ssh-authorized-keys" "/bootc_authorized_ssh_keys/root"

# podman run --privileged --pid=host --user=root:root -v /var/lib/containers:/var/lib/containers -v /dev:/dev --security-opt label=type:unconfined_t -v /:/target quay.io/toharris/rhel-bootc:summit-2025 bootc install to-existing-root --acknowledge-destructive --root-ssh-authorized-keys /target/home/rhel/.ssh/authorized_keys

# Add password root logins
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config.d/ansible_permit_root_login.conf

# Add name based resolution for internal IPs
echo "10.0.2.2 builder.${GUID}.${DOMAIN}" >> /etc/hosts
cp /etc/hosts ~/etc/hosts

echo "DONE" >> /root/job.log

