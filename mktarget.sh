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

  chmod 0700 ${targetDir}/root
  chmod 1777 ${targetDir}/tmp

  ln -sf usr/lib ${targetDir}/lib
  ln -sf ../tmp ${targetDir}/var/cache
  ln -sf ../tmp ${targetDir}/var/log
  ln -sf ../tmp ${targetDir}/var/tmp
}

function musl() {
  prepare musl-${MUSL_VER} BUILD

  msg 'Configuring musl'
  CROSS_COMPILE=${crossPrefix} \
    ../configure --host=${TARGET} --prefix=/usr --disable-static || exit 1

  msg 'Compiling musl'
  make -j4 || exit 1

  msg 'Installing musl'
  make install DESTDIR=${targetDir} || exit 1

  rm -rf ${targetDir}/usr/include
  rm -rf ${targetDir}/usr/lib/ld-*.so*
  rm -rf ${targetDir}/usr/lib/lib*.a
  rm -rf ${targetDir}/usr/lib/*.o

  ln -sf libc.so ${targetDir}/usr/lib/ld-linux.so.3
}

function libgcc() {
  msg 'Copying libgcc from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libgcc_s.so.1 ${targetDir}/usr/lib
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

sanityCheck

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
  busybox)
    busybox
    ;;
  *)
    rm -rf ${targetDir}
    filesystem
    musl
    libgcc
    busybox
    trim
    ;;
esac
