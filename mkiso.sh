#!/bin/bash
# Include the helper functions
source $(dirname "$0")/helper_functions.sh

set -e
set -u

# source:
# - http://codeghar.wordpress.com/2011/12/14/automated-customized-debian-installation-using-preseed/
# - the gist

# required packages (apt-get install)
# xorriso
# syslinux

PROJECT_DIR=$(pwd)
if [[ ! -v DEBIAN_ISO ]]; then
  echo "Env DEBIAN_ISO is not available"
  exit 1
fi

DEBIAN_MAJOR=$(echo -n ${DEBIAN_VERSION}|cut -d. -f 1)
echo "Debian major version is ${DEBIAN_MAJOR}.."
if [[ ${DEBIAN_MAJOR} != "11" && ${DEBIAN_MAJOR} != "12" ]]; then
  echo "Debian major version not supported!"
  exit 1
fi

ISOFILE=${PROJECT_DIR}/debian/${DEBIAN_ISO}
if [[ -v DEBIAN_VERSION ]]; then
  ISOFILE_FINAL=${PROJECT_DIR}/final/gunet-jeos-debian-${DEBIAN_VERSION}.iso
else
  ${PROJECT_DIR}/final/gunet-jeos-debian.iso
fi

ISODIR=${PROJECT_DIR}/isofiles
ISODIR_WRITE=${ISODIR}-rw
PRESEED_DIR=${PROJECT_DIR}/gunet

# check for environment variables
if [[ ${NET_STATIC} == "yes" ]]; then
  if [[ ${NET_IP} == "notset" || ${NET_GATEWAY} == "notset" || \
  ${NET_NAMESERVERS} == "notset" || ${NET_HOSTNAME} == "notset" || \
  ${NET_DOMAIN} == "notset" ]]; then
    echo "Environment variable NET_STATIC is yes but some NET_* variables are not set!"
    exit 1
  fi
  sed -i'' -e "s/^#STATIC#//g" ${PRESEED_DIR}/preseed.cfg
fi
if [[ ${NET_IP} != "notset" ]]; then
  if [[ ${NET_GATEWAY} == "notset" || ${NET_NAMESERVERS} == "notset" ]]; then
    echo "Environment variable NET_IP is set but NET_GATEWAY or NET_NAMESERVERS are not!"
    exit 1
  fi
  NET_IP_PLAIN=$(cidr_ip ${NET_IP})
  NET_PREFIX=$(cidr_prefix ${NET_IP})
  if [[ ${NET_PREFIX} == "" ]]; then
    echo "NET_IP should be of CIDR form"
    exit 1
  fi
  NET_NETMASK=$(netmask_of_prefix ${NET_PREFIX})

  echo "Network configuration:"
  echo "IP (CIDR):   ${NET_IP}"
  echo "IP (plain):  ${NET_IP_PLAIN}"
  echo "IP Prefix:   ${NET_PREFIX}"
  echo "Netmask:     ${NET_NETMASK}"
  echo "IP gateway:  ${NET_GATEWAY}"
  echo "Nameservers: ${NET_NAMESERVERS}"
  echo "-------------------------------"

  sed -i'' -e "s/^#NET#//g" -e "s/__IP__/${NET_IP_PLAIN}/" -e "s/__NETMASK__/${NET_NETMASK}/" \
  -e "s/__GATEWAY__/${NET_GATEWAY}/" -e "s/__NAMESERVERS__/${NET_NAMESERVERS}/" ${PRESEED_DIR}/preseed.cfg
fi

if [[ ${NET_HOSTNAME} != "notset" ]]; then
  if [[ ${NET_DOMAIN} == "notset" ]]; then
    echo "Environment variable NET_HOSTNAME is set but NET_DOMAIN is not!"
    exit 1
  fi
  echo "Hostname configuration:"
  echo "Hostname:    ${NET_HOSTNAME}"
  echo "Domain:      ${NET_DOMAIN}"
  echo "----------------------------"

  sed -i'' -e "s/^#HOST#//g" \
  -e "s/__HOSTNAME__/${NET_HOSTNAME}/" -e "s/__DOMAIN__/${NET_DOMAIN}/" ${PRESEED_DIR}/preseed.cfg
fi

if [[ ${ROOT_PASSWORD} != "notset" ]]; then
  echo "Root passwd: ${ROOT_PASSWORD}"
  sed -i'' -e "s/^#ROOT#//g" -e "s/__ROOT_PASSWORD__/${ROOT_PASSWORD}/" ${PRESEED_DIR}/preseed.cfg
fi

sed -i "s/^M//" $PRESEED_DIR/custom_script.sh

if [[ ! -e /dev/loop0 ]]; then
  echo 'Creating loop device..'
  mknod -m 0660 /dev/loop0 b 7 0
fi
echo 'mounting ISO9660 filesystem...'
# source: http://wiki.debian.org/DebianInstaller/ed/EditIso
[ -d $ISODIR ] || mkdir -p $ISODIR
mount -o loop $ISOFILE $ISODIR

echo 'copying to writable dir...'
rm -rf $ISODIR_WRITE || true
[ -d $ISODIR_WRITE ] || mkdir -p $ISODIR_WRITE
rsync --info=progress2 -a -H --exclude=TRANS.TBL $ISODIR/ $ISODIR_WRITE
echo 'unmount iso dir'
umount $ISODIR

echo 'correcting permissions...'
chmod 755 -R $ISODIR_WRITE

echo "Enabling source.list for Debian major version.."
cp $PRESEED_DIR/sources.${DEBIAN_MAJOR}.list $PRESEED_DIR/sources.list

echo 'copying preseed file...'
cp gunet/isolinux.cfg $ISODIR_WRITE/isolinux/
cp -r $PRESEED_DIR/ $ISODIR_WRITE/

echo 'edit isolinux/txt.cfg...'
sed 's/initrd.gz/initrd.gz file=\/cdrom\/gunet\/preseed.cfg/' -i $ISODIR_WRITE/isolinux/txt.cfg

echo 'creating initrd.gz..'
mkdir -p irmod
cd irmod
gzip -d < $ISODIR_WRITE/install.amd/initrd.gz | \
cpio --extract --make-directories --no-absolute-filenames
cp $PRESEED_DIR/preseed.cfg preseed.cfg
chown root:root preseed.cfg 
chmod o+w $ISODIR_WRITE/install.amd/initrd.gz
find . | cpio -H newc --create | \
        gzip -9 > $ISODIR_WRITE/install.amd/initrd.gz
chmod o-w $ISODIR_WRITE/install.amd/initrd.gz
cd ../
rm -fr irmod/

echo 'fixing MD5 checksums...'
pushd $ISODIR_WRITE
  md5sum $(find -type f) > md5sum.txt
popd

echo 'making ISO...'
genisoimage -o $ISOFILE_FINAL \
   -r -J -no-emul-boot -boot-load-size 4 \
   -boot-info-table -quiet \
   -b isolinux/isolinux.bin \
   -c isolinux/boot.cat $ISODIR_WRITE

isohybrid $ISOFILE_FINAL

rm -r isofiles*

