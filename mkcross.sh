. config.sh
. inc/common.sh

function fetch() {
  msg 'Fetching'
  fetchPkg "https://cdn.kernel.org/pub/linux/kernel/v3.x/linux-${LINUX_VER}.tar.xz"
  fetchPkg "http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.bz2"
  fetchPkg "ftp://gd.tuwien.ac.at/gnu/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2"
  fetchPkg "http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.bz2"
  fetchPkg "http://www.musl-libc.org/releases/musl-${MUSL_VER}.tar.gz"
  msg 'Fetched everything'
}

function trim() {
  msg 'Removing cross/share'
  rm -rf ${crossDir}/share

  msg 'Stripping host binaries'
  strip ${crossDir}/bin/*
  strip ${crossDir}/libexec/gcc/${TARGET}/${GCC_VER}/*
  strip ${crossDir}/libexec/gcc/${TARGET}/${GCC_VER}/plugin/*

  msg 'Stripping target binaries'
  strip ${crossDir}/${TARGET}/bin/*
  ${crossPrefix}strip ${crossDir}/${TARGET}/lib/*.so*
}

function kernelHeaders() {
  prepare linux-${LINUX_VER} BUILD-cross

  msg 'Installing kernel headers'
  cd .. && make ARCH=arm INSTALL_HDR_PATH=${crossDir}/${TARGET} headers_install
}

function binutils() {
  prepare binutils-${BINUTILS_VER} BUILD-cross

  msg 'Configuring toolchain binutils'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib || exit 1

  msg 'Compiling toolchain binutils'
  make -j4 || exit 1

  msg 'Installing toolchain binutils'
  make install || exit 1
}

function gcc() {
  prepare isl-${ISL_VER} BUILD-cross
  prepare gcc-${GCC_VER} BUILD-cross

  # Link isl into GCC source-tree, to simplfy configure command-line.
  ln -sf ${buildDir}/isl-${ISL_VER} ../isl

  msg 'Configuring toolchain GCC'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
		 --enable-languages=c --disable-static || exit 1

  msg 'Compiling toolchain GCC'
  make -j4 all-gcc || exit 1

  msg 'Installing toolchain GCC'
  make install-gcc || exit 1
}

# We have a poblem here; libgcc depends on libc, but libc also needs libgcc since GCC generates code
# that call functions from libgcc (e.g. floating-point helper functions). We solve that cyclic
# dependency issue by first compiling a limited libgcc (static only, without supports for threads).
# Bootstrap libgcc is used to build libc and afeter that we can build a fully-functional libgcc.
function libgcc1() {
  prepare gcc-${GCC_VER} BUILD-cross-libgcc1

  msg 'Configuring toolchain bootstrap libgcc'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
		 --enable-languages=c --disable-shared --disable-threads || exit 1

  msg 'Compiling toolchain bootstrap libgcc'
  make -j4 all-target-libgcc || exit 1

  msg 'Installing toolchain bootstrap libgcc'
  make install-target-libgcc || exit 1
}

function musl() {
  prepare musl-${MUSL_VER} BUILD-cross

  msg 'Configuring toolchain musl'
  CROSS_COMPILE=${crossPrefix} \
    ../configure --target=${TARGET} --prefix=${crossDir}/${TARGET} --disable-static

  msg 'Compiling toolchain musl'
  make -j4 || exit 1

  msg 'Installing toolchain musl'
  make install || exit 1
}

function libgcc() {
  prepare gcc-${GCC_VER} BUILD-cross

  msg 'Compiling toolchain libgcc'
  make -j4 all-target-libgcc || exit 1

  msg 'Installing toolchain libgcc'
  make install-target-libgcc || exit 1

  rm -rf ${crossDir}/lib/gcc/${TARGET}/${GCC_VER}/include-fixed
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
  kernelHeaders)
    kernelHeaders
    ;;
  binutils)
    binutils
    ;;
  gcc)
    gcc
    ;;
  libgcc1)
    libgcc1
    ;;
  musl)
    musl
    ;;
  libgcc)
    libgcc
    ;;
  *)
    rm -rf ${crossDir}
    clean
    binutils
    gcc
    libgcc1
    musl
    libgcc
    trim
    ;;
esac