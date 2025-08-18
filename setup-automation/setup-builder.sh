#!/bin/bash
set -euxo pipefail

# Log into terms based registry and stage bootc and bib images
mkdir -p ~/.config/containers
cat<<EOF> ~/.config/containers/auth.json
{
    "auths": {
      "registry.redhat.io": {
        "auth": "${REGISTRY_PULL_TOKEN}"
      }
    }
  }
EOF

# Log into terms based registry and stage bootc and bib images
BOOTC_RHEL_VER=10.0
podman pull registry.redhat.io/rhel10/rhel-bootc:$BOOTC_RHEL_VER registry.redhat.io/rhel10/bootc-image-builder:$BOOTC_RHEL_VER

# Start the target VM, created from the image-mode-basics lab image and maintained in the GCP compute image for this lab

# virsh start bootc2

# set up SSL for fully functioning registry
# Enable EPEL for RHEL 10
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y certbot

# request certificates
certbot certonly --standalone --preferred-challenges http -d builder."${GUID}"."${DOMAIN}" --non-interactive --agree-tos -m trackbot@instruqt.com -v

# run a local registry with the provided certs
podman run --privileged -d \
  --name registry \
  -p 5000:5000 \
  -v /etc/letsencrypt/live/builder."${GUID}"."${DOMAIN}"/fullchain.pem:/certs/fullchain.pem \
  -v /etc/letsencrypt/live/builder."${GUID}"."${DOMAIN}"/privkey.pem:/certs/privkey.pem \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem \
  -e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem \
  quay.io/mmicene/registry:2

# For the target bootc system build, we need to set up a few config files to operate in the lab environment
# create sudoers drop in and etc structure to add to container
mkdir -p ~/etc/sudoers.d/
echo "%wheel  ALL=(ALL)   NOPASSWD: ALL" >> ~/etc/sudoers.d/wheel

# create config.json for BIB to add a user / pass
cat <<EOF> ~/config.json
{
  "blueprint": {
    "customizations": {
      "user": [
        {
          "name": "core",
          "password": "redhat",
           "groups": [
	            "wheel"
	          ]
        }
      ]
    }
  }
}
EOF

# create updated bootc containerfile from image-mode-basics
cat <<EOF> ~/Containerfile
FROM registry.redhat.io/rhel10/rhel-bootc:$BOOTC_RHEL_VER

ADD etc /etc

RUN dnf install -y httpd vim
RUN systemctl enable httpd

EOF

# create V3 index.html relocated containerfile
cat <<EOM> ~/Containerfile.index
FROM registry.redhat.io/rhel10/rhel-bootc:$BOOTC_RHEL_VER

ADD etc /etc

RUN dnf install -y httpd vim

RUN systemctl enable httpd

RUN <<EOF 
    mv /var/www /usr/share/www
    sed -i 's-/var/www-/usr/share/www-' /etc/httpd/conf/httpd.conf
EOF

RUN echo "New application coming soon!" > /usr/share/www/html/index.html

EOM

# Add name based resolution for internal IPs
echo "10.0.2.2 builder.${GUID}.${DOMAIN}" >> /etc/hosts
cp /etc/hosts ~/etc/hosts

#podman build -t ${HOSTNAME}.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/test-bootc .
#podman push ${HOSTNAME}.${INSTRUQT_PARTICIPANT_ID}.instruqt.io:5000/test-bootc

