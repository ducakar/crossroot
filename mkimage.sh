. config.sh
. etc/common.sh

fakeroot << EOF
mkdir -p ${imagesDir} && cd ${targetDir}

mknod -m 0600 dev/console c 5 1
mknod -m 0666 dev/null c 1 3

chmod 4755 usr/bin/busybox

mkyaffs2 . ${imagesDir}/rootfs.yaffs2
tar cf ${imagesDir}/rootfs.tar *
EOF
