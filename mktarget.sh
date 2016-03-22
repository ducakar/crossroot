. config.sh
. etc/common.sh

function fetch() {
  msg 'Fetching'
  fetchPkg "https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
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
  msg 'Creating filesystem'

  mkdir -p ${targetDir}/{dev,etc,proc,root,run,sys,tmp,usr,var}
  mkdir -p ${targetDir}/usr/{bin,lib,share}
  mkdir -p ${targetDir}/var/lib

  chmod 0750 ${targetDir}/root
  chmod 1777 ${targetDir}/tmp

  ln -sf usr/bin ${targetDir}/bin
  ln -sf usr/lib ${targetDir}/lib
  ln -sf ../tmp ${targetDir}/var/cache
  ln -sf ../tmp ${targetDir}/var/log
  ln -sf ../tmp ${targetDir}/var/tmp
}

function musl() {
  msg 'Copying musl from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libc.so ${targetDir}/usr/lib/libc.so
  ln -s usr/lib/libc.so ${targetDir}/lib/ld-linux.so.3
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
  all)
    rm -rf ${targetDir}
    filesystem
    musl
    libgcc
    zlib
    busybox
    trim
    ;;
esac
