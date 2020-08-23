mkdir mnt
sudo mount -o loop ubuntu-14.04.2-server-amd64.iso mnt

mkdir extract-cd
sudo rsync --exclude=/install/filesystem.squashfs -a mnt/ extract-cd
sudo unsquashfs mnt/install/filesystem.squashfs
sudo mv squashfs-root edit

sudo cp /etc/resolv.conf edit/etc/
sudo mount --bind /dev/ edit/dev
sudo chroot edit
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

export HOME=/root
export LC_ALL=C

dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl


apt-get clean
rm -rf /tmp/* ~/.bash_history
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

umount /proc || umount -lf /proc
umount /sys
umount /dev/pts
umount /dev
exit

chmod +w extract-cd/install/filesystem.manifest
sudo su
chroot edit dpkg-query -W --showformat='{Package} {Version}\n' > extract-cd/install/filesystem.manifest
exit
sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs

sudo su
printf (du -sx --block-size=1 edit | cut -f1) > extract-cd/casper/filesystem.size
exit

cd extract-cd
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

sudo mkisofs -D -r -V "IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../my-custom-ubuntu.iso .