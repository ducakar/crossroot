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
  ln -sf libc.so ${targetDir}/usr/lib/ld-musl-${TARGET/-none-linux-*}.so.1
  ln -sf libc.so ${targetDir}/usr/lib/libm.so
}

function libgcc() {
  msg 'Copying libgcc from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libgcc_s.so.1 ${targetDir}/usr/lib
  install -Dm 755 ${crossDir}/${TARGET}/lib/libstdc++.so.6 ${targetDir}/usr/lib
  ln -sf libstdc++.so.6 ${targetDir}/usr/lib/libstdc++.so
}

function zlib() {
  msg 'Copying zlib from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libz.so.1 ${targetDir}/usr/lib
  ln -sf libz.so.1 ${targetDir}/usr/lib/libz.so
}

function libressl() {
  msg 'Copying libressl from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libcrypto.so.38 ${targetDir}/usr/lib
  install -Dm 755 ${crossDir}/${TARGET}/lib/libssl.so.39 ${targetDir}/usr/lib
}

function libpng() {
  msg 'Copying libpng from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libpng16.so.16 ${targetDir}/usr/lib
}

function jpeglib() {
  msg 'Copying jpeglib from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libjpeg.so.9 ${targetDir}/usr/lib
}

function freetype() {
  msg 'Copying freetype from toolchain'
  install -Dm 755 ${crossDir}/${TARGET}/lib/libfreetype.so.6 ${targetDir}/usr/lib
}

function busybox() {
  prepare busybox-${BUSYBOX_VER} busybox-${BUSYBOX_VER} BUILD

  cd ..
  cp ${rootDir}/etc/busybox-config .config
  sed "s/^CONFIG_CROSS_COMPILER_PREFIX=.*/CONFIG_CROSS_COMPILER_PREFIX=\"${TARGET}-\"/" -i .config

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
  prepare mono-${MONO_VER} mono-${MONO_VER} BUILD

  msg 'Configuring mono'
  ../configure --host=${TARGET} --prefix=/usr --disable-nls --disable-boehm --without-x \
	       --disable-mcs-build --with-mcs-docs=no --enable-system-aot \
	       --enable-minimal=profiler || exit 1

  msg 'Compiling mono'
  make -j4 || exit 1

  msg 'Installing mono'
  make install DESTDIR=${targetDir} || exit 1

  cp -r /usr/lib/mono/{4.5,gac} ${targetDir}/usr/lib/mono
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
  libpng)
    libpng
    ;;
  jpeglib)
    jpeglib
    ;;
  freetype)
    freetype
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
    libpng
    jpeglib
    freetype
    busybox
    openssh
    trim
    ;;
esac
