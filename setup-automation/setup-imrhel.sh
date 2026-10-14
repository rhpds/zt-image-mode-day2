#!/bin/bash
set -x
trap 'echo "FATAL: setup failed at line ${LINENO}" >> /tmp/progress.log; exit 1' ERR

echo "Setup imrhel host for day2 lab" > /tmp/progress.log
chmod 666 /tmp/progress.log

# Register and install git before library fetch
dnf -y remove katello-ca-consumer-* 2>/dev/null || true
subscription-manager clean
subscription-manager register --activationkey="${ACTIVATION_KEY}" --org="${ORG_ID}" --force
dnf install -y git

LIBDIR=/tmp/lab-lib-$$
git clone --depth=1 https://github.com/rhel-labs/lab-setup "${LIBDIR}"
. "${LIBDIR}/common.sh"

# --- lab configuration ---
IMRHEL_HOST="imrhel.${GUID}.${DOMAIN}"
# -------------------------

# GCP agents left in image cause issues with reboot timing
systemctl stop \
  google-disk-expand.service \
  google-guest-agent.service \
  google-osconfig-agent.service \
  google-oslogin-cache.timer \
  google-startup-scripts.service \
  google-guest-agent-manager.service \
  google-guest-compat-manager.service \
  google-oslogin-cache.service \
  google-shutdown-scripts.service || true

dnf -y remove \
  google-guest-agent \
  google-compute-engine-oslogin \
  google-compute-engine \
  google-osconfig-agent || true

echo "GCP agents removed" >> /tmp/progress.log

dnf install -y podman skopeo

# dnf-automatic interferes with the reboot timing during bootc conversion
systemctl disable --now dnf-automatic.timer || true

add_local_host "${IMRHEL_HOST}"

# Convert system to image mode using a pre-built bootc image
podman run --privileged --pid=host --user=root:root \
  -v /var/lib/containers:/var/lib/containers \
  -v /dev:/dev --security-opt label=type:unconfined_t \
  -v /:/target \
  quay.io/mmicene/im-day2-tgt:9.8 \
  bootc install to-existing-root --acknowledge-destructive \
  --root-ssh-authorized-keys /target/home/rhel/.ssh/authorized_keys
echo "bootc conversion complete" >> /tmp/progress.log

# The deployment checksum directory changes each provision — detect it dynamically
STATEROOT=$(ls -d /ostree/deploy/default/deploy/*/)

# Allow root SSH login for Ansible access to the new bootc deployment
echo "PermitRootLogin yes" >> "${STATEROOT}/etc/ssh/sshd_config.d/ansible_permit_root_login.conf"

# Carry existing credentials into the new bootc tree
# passwd/group are not copied to preserve UID/GID consistency
\cp -f /etc/shadow "${STATEROOT}/etc/shadow"

# Replicate hosts entry into the bootc deployment
# stateroot hosts file is not live — write directly, don't use add_local_host
echo "10.0.2.2 ${IMRHEL_HOST}" >> "${STATEROOT}/etc/hosts"

cleanup_subscription
cleanup_tmpfiles
echo "imrhel setup complete" >> /tmp/progress.log
