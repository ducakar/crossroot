. config.sh
. etc/common.sh

function fetch() {
  msg 'Fetching'
  fetchPkg "https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
  fetchPkg "http://www.obsd.si/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz"
  fetchPkg "http://download.mono-project.com/sources/mono/mono-${MONO_VER}.tar.bz2"
  msg 'Fetched everything'
}

function trim() {
  msg 'Removing includes, locales, manual ...'
  rm -rf ${targetDir}/usr/include
  rm -rf ${targetDir}/usr/lib/*.a
  rm -rf ${targetDir}/usr/lib/*.la
  rm -rf ${targetDir}/usr/lib/pkgconfig
  rm -rf ${targetDir}/usr/share

  msg 'Stripping target binaries'
  ${crossPrefix}strip ${targetDir}/usr/bin/*
  ${crossPrefix}strip ${targetDir}/usr/lib/*.so*
}

function filesystem() {
  cp -af etc/root ${targetDir}
}

function musl() {
  msg 'Copying musl from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libc.so ${targetDir}/usr/lib
  ln -s libc.so ${targetDir}/usr/lib/ld-musl-arm.so.1
}

function libgcc() {
  msg 'Copying libgcc from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libgcc_s.so.1 ${targetDir}/usr/lib
  install -Dm 755 ${crossDir}/${TARGET}/lib/libstdc++.so.6 ${targetDir}/usr/lib
}

function zlib() {
  msg 'Copying zlib from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libz.so.1 ${targetDir}/usr/lib/libz.so.1
}

function libressl() {
  msg 'Copying libressl from toolchain'
  install -m 755 ${crossDir}/${TARGET}/lib/libcrypto.so.38 ${targetDir}/usr/lib/libcrypto.so.38
  install -m 755 ${crossDir}/${TARGET}/lib/libssl.so.39 ${targetDir}/usr/lib/libssl.so.39
}

function busybox() {
  prepare busybox-${BUSYBOX_VER} busybox-${BUSYBOX_VER} BUILD

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
  prepare openssh-${OPENSSH_VER} openssh-${OPENSSH_VER} BUILD

  msg 'Configuring openssh'
  # It calls "strip" instead of "${TARGET}-strip". Anyway, we strip all binaries aftwrwards.
  ../configure --host=${TARGET} --prefix=/usr --sysconfdir=/etc --disable-etc-default-login \
	       --disable-strip || exit 1

  msg 'Compiling openssh'
  make -j4 || exit 1

  msg 'Installing openssh'
  make install-nokeys DESTDIR=${targetDir} || exit 1
}

function mono() {
  prepare mono-${MONO_VER_FULL} mono-${MONO_VER} BUILD

  msg 'Configuring mono'
  ../configure --host=${TARGET} --prefix=/usr --disable-nls --disable-boehm --without-x \
	       --disable-mcs-build --with-mcs-docs=no --enable-system-aot \
	       --enable-minimal=profiler || exit 1

  msg 'Compiling mono'
  make -j4 || exit 1

  msg 'Installing mono'
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
  libressl)
    libressl
    ;;
  busybox)
    busybox
    ;;
  openssh)
    openssh
    ;;
  mono)
    mono
    ;;
  all)
    rm -rf ${targetDir}
    filesystem
    musl
    libgcc
    zlib
    libressl
    busybox
    openssh
    mono
    trim
    ;;
esac
