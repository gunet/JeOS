#!/bin/sh
echo "apt update.."
apt -qq update
echo "Install prerequisite packages.."
apt -qqy install apt-transport-https ca-certificates \
  curl gnupg2 software-properties-common
echo "Install git.."
apt -qqy git
echo "Add Docker repository GPG key.."
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
echo "Add Docker reposity.."
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
echo "apt update (second time).."
apt update
echo "Install Docker.."
apt -qqy install docker-ce
echo "Show docker status.."
systemctl status docker
echo "Running docker version.."
docker version
echo "Dowloading docker-compose.."
curl -fsSL https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 >/usr/local/bin/docker-compose
chmod 0755 /usr/local/bin/docker-compose
echo "Checking docker-compose version"
/usr/local/bin/docker-compose version
