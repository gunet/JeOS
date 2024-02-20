#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade

 dpkg --purge console-setup console-setup-linux \
  keyboard-configuration xkb-data kbd apt-utils \
  nftables usbutils installation-report nano \
  emacsen-common discover discover-data dmidecode \
  laptop-detect eject libsqlite3-0 debconf-i18n gdbm-l10n \
  os-prober libtext-iconv-perl libtext-wrapi18n-perl \
  libtext-charwidth-perl readline-common systemd-timesyncd \
  tasksel tasksel-data openssh-client openssh-sftp-server gcc-9-base:amd64

apt-get -y --purge autoremove

apt-get -y install acpi-support-base openssh-server \
  iptables-persistent deborphan anacron net-tools \
  wget telnet tcpdump lsof iputils-ping cdebconf

apt-get -y update
apt-get -y upgrade
#apt-get -y -t bullseye-backports upgrade
#apt-get -y -t bullseye-backports dist-upgrade

exit 0;
