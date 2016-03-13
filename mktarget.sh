. config.sh
. inc/common.sh

function fetch() {
  msg 'Fetching'
  fetchPkg "https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
  msg 'Fetched everything'
}

function trim() {
  msg 'Removing includes, locales, manual ..,'
  rm -rf ${targetDir}/usr/include
  rm -rf ${targetDir}/usr/share/{man,info,locale}

  msg 'Stripping target binaries'
  ${crossPrefix}strip ${targetDir}/usr/bin/*
  ${crossPrefix}strip ${targetDir}/usr/lib/*.so*
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
  rm -rf ${targetDir}/usr/lib/lib*.a
  rm -rf ${targetDir}/usr/lib/*.o

  mv ${targetDir}/lib/ld-musl-arm.so.1 ${targetDir}/lib/ld-linux.so.3
}

function libgcc() {
  msg 'Copying libgcc from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libgcc_s.so.1 ${targetDir}/usr/lib
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
  musl)
    musl
    ;;
  libgcc)
    libgcc
    ;;
  *)
    rm -rf ${targetDir}
    ;;
esac
