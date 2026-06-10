#!/bin/bash
echo "Starting Docker installation script for Debian 13.."
apt -qq update
apt -qqy install ca-certificates curl
echo "Adding Docker GPG key.."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "Adding Docker repository.."
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
echo "Updating apt.."
apt -qq update
echo "Installing Docker.."
apt -qqy install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "Docker version.."
docker version