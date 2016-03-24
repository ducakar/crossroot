. config.sh
. etc/common.sh

function fetch() {
  msg 'Fetching'
  fetchPkg "https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
  fetchPkg "http://www.obsd.si/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz"
  msg 'Fetched everything'
}

function trim() {
  msg 'Removing includes, locales, manual ...'
  rm -rf ${targetDir}/usr/include
  rm -rf ${targetDir}/usr/share/{man,info,locale}

  msg 'Stripping target binaries'
  ${crossPrefix}strip ${targetDir}/usr/bin/*
  ${crossPrefix}strip ${targetDir}/usr/lib/*.so*
}

function filesystem() {
  cp -af etc/root ${targetDir}
}

function musl() {
  msg 'Copying musl from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libc.so ${targetDir}/usr/lib/libc.so
  ln -s libc.so ${targetDir}/usr/lib/ld-linux.so.3
}

function libgcc() {
  msg 'Copying libgcc from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libgcc_s.so.1 ${targetDir}/usr/lib/libgcc_s.so.1
}

function zlib() {
  msg 'Copying zlib  from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libz.so.1 ${targetDir}/usr/lib/libz.so.1
}

function busybox() {
  prepare busybox-${BUSYBOX_VER} BUILD

  cd .. && cp ${rootDir}/etc/busybox-config .config

  msg 'Compiling busybox'
  make -j4 || exit 1

  msg 'Installing busybox'
  make install || exit 1

  install -m 755 _install/bin/busybox ${targetDir}/usr/bin

  symlinks=`echo _install/bin/* _install/sbin/* _install/usr/bin/* _install/usr/sbin/* | sort`

  for s in ${symlinks}; do
    [[ -L ${s} ]] && ln -sf busybox ${targetDir}/usr/bin/`basename ${s}`
  done
}

function openssh() {
  prepare openssh-${OPENSSH_VER} BUILD

  msg 'Configuring openssh'
  ../configure --host=arm-linux-gnueabi --prefix=/usr || exit 1

  msg 'Compiling openssh'
  make -j4 || exit 1

  msg 'Installing openssh'
  make install DESTDIR=${targetDir} || exit 1
}

case ${1} in
  fetch)
    fetch
    ;;
  clean)
    clean
    ;;
  trim)
    trim
    ;;
  filesystem)
    filesystem
    ;;
  musl)
    musl
    ;;
  libgcc)
    libgcc
    ;;
  zlib)
    zlib
    ;;
  busybox)
    busybox
    ;;
  openssh)
    openssh
    ;;
  all)
    rm -rf ${targetDir}
    filesystem
    musl
    libgcc
    zlib
    busybox
    openssh
    trim
    ;;
esac
