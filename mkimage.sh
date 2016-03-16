. config.sh
. etc/common.sh

sanityCheck

fakeroot << EOF
mknod -m 0600 ${targetDir}/dev/console c 5 1
mknod -m 0666 ${targetDir}/dev/null c 1 3

mkyaffs2 ${targetDir} ${imagesDir}/rootfs.yaffs2
EOF
