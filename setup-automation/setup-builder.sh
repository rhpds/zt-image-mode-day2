#!/bin/bash
set -x
trap 'echo "FATAL: setup failed at line ${LINENO}" >> /tmp/progress.log; exit 1' ERR

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Setup build host for day2 lab" > /tmp/progress.log
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
BOOTC_RHEL_VER=10.2
BUILDER_HOST="builder-${GUID}.${DOMAIN}"
REGISTRY_HOST="registry-${GUID}.${DOMAIN}"
# -------------------------

setup_libvirt
echo "Libvirt configured" >> /tmp/progress.log

podman login registry.redhat.io --username token --password "${REGISTRY_PULL_TOKEN}"
pull_images root \
  registry.redhat.io/rhel10/rhel-bootc:${BOOTC_RHEL_VER} \
  registry.redhat.io/rhel10/bootc-image-builder:${BOOTC_RHEL_VER}
echo "Base images pulled" >> /tmp/progress.log

setup_ssl_registry "${REGISTRY_HOST}"
echo "Registry up at ${REGISTRY_HOST}" >> /tmp/progress.log

SETUP_FILES=$(fetch_setup_files setup-files)
cp "${SETUP_FILES}/config.json" /root/config.json
cp "${SETUP_FILES}/Containerfile" /root/Containerfile
cp "${SETUP_FILES}/Containerfile.index" /root/Containerfile.index
echo "Setup files staged" >> /tmp/progress.log

mkdir -p /root/etc/sudoers.d
echo "%wheel  ALL=(ALL)   NOPASSWD: ALL" > /root/etc/sudoers.d/wheel

add_local_host "${BUILDER_HOST}"
add_local_host "${REGISTRY_HOST}"
cp /etc/hosts /root/etc/hosts

persist_env_var REGISTRY "${REGISTRY_HOST}"

cleanup_registry_auth
cleanup_subscription
cleanup_certbot
cleanup_tmpfiles
echo "Builder setup complete" >> /tmp/progress.log
