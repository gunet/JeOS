#!/bin/bash
set -e
set -u

# source:
# - http://codeghar.wordpress.com/2011/12/14/automated-customized-debian-installation-using-preseed/
# - the gist

# required packages (apt-get install)
# xorriso
# syslinux

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <debian iso filename>"
  exit 1
fi

PROJECT_DIR=$(pwd)
ISOFILE=${PROJECT_DIR}/debian/${DEBIAN_ISO}
ISOFILE_FINAL=${PROJECT_DIR}/final/gunet-jeos.iso
ISODIR=${PROJECT_DIR}/isofiles
ISODIR_WRITE=${ISODIR}-rw
PRESEED_DIR=${PROJECT_DIR}/gunet

sed -i "s/^M//" $PRESEED_DIR/custom_script.sh

echo 'mounting ISO9660 filesystem...'
# source: http://wiki.debian.org/DebianInstaller/ed/EditIso
[ -d $ISODIR ] || mkdir -p $ISODIR
mount -o loop $ISOFILE $ISODIR

echo 'copying to writable dir...'
rm -rf $ISODIR_WRITE || true
[ -d $ISODIR_WRITE ] || mkdir -p $ISODIR_WRITE
rsync -a -H --exclude=TRANS.TBL $ISODIR/ $ISODIR_WRITE
echo 'unmount iso dir'
umount $ISODIR

echo 'correcting permissions...'
chmod 755 -R $ISODIR_WRITE

echo 'copying preseed file...'
cp -r $PRESEED_DIR/ $ISODIR_WRITE/

echo 'edit isolinux/txt.cfg...'
sed 's/initrd.gz/initrd.gz file=\/cdrom\/gunet\/preseed.cfg/' -i $ISODIR_WRITE/isolinux/txt.cfg

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
   -boot-info-table \
   -b isolinux/isolinux.bin \
   -c isolinux/boot.cat $ISODIR_WRITE

isohybrid $ISOFILE_FINAL

rm -r isofiles*

