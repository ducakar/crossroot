. config.sh
. etc/common.sh

fakeroot << EOF
mkdir -p ${imagesDir} && cd ${targetDir}

mknod -m 0600 dev/console c 5 1
mknod -m 0666 dev/null c 1 3

chmod 4755 usr/bin/busybox

tar cf ${imagesDir}/rootfs.tar *
EOF

dd if=/dev/zero of=${imagesDir}/rootfs.img bs=1M count=256
mkfs.ext3 -L root ${imagesDir}/rootfs.img
sudo mount -o loop ${imagesDir}/rootfs.img /mnt/temp
sudo tar xf ${imagesDir}/rootfs.tar -C /mnt/temp
sudo umount /mnt/temp
