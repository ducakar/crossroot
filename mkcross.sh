. config.sh
. etc/common.sh

function fetch() {
  msg 'Fetching'
  fetchPkg "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${LINUX_VER}.tar.xz"
  fetchPkg "http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.bz2"
  fetchPkg "http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.xz"
  fetchPkg "ftp://gd.tuwien.ac.at/gnu/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2"
  fetchPkg "http://www.musl-libc.org/releases/musl-${MUSL_VER}.tar.gz"
  fetchPkg "http://zlib.net/zlib-${ZLIB_VER}.tar.xz"
  fetchPkg "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz"
  fetchPkg "http://downloads.sourceforge.net/sourceforge/libpng/libpng-${LIBPNG_VER}.tar.xz"
  fetchPkg "http://www.ijg.org/files/jpegsrc.v${JPEGLIB_VER}.tar.gz"
  fetchPkg "http://download.savannah.gnu.org/releases/freetype//freetype-${FREETYPE_VER}.tar.bz2"
  fetchPkg "https://www.libsdl.org/release/SDL-${SDL_VER}.tar.gz"
  fetchPkg "https://www.libsdl.org/projects/SDL_image/release/SDL_image-${SDL_IMAGE_VER}.tar.gz"
  fetchPkg "https://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-${SDL_TTF_VER}.tar.gz"
  msg 'Fetched everything'
}

function trim() {
  msg 'Removing cross/[target]/share'
  rm -rf ${crossDir}/share
  rm -rf ${crossDir}/${TARGET}/share

  msg 'Stripping host binaries'
  strip ${crossDir}/bin/*
  strip ${crossDir}/${TARGET}/bin/*

  msg 'Stripping target binaries'
  ${crossPrefix}strip ${crossDir}/${TARGET}/lib/*.so*
}

function kernelHeaders() {
  prepare linux-${LINUX_VER} linux-${LINUX_VER} BUILD-cross

  msg 'Installing kernel headers'
  cd .. && make ARCH=arm INSTALL_HDR_PATH=${crossDir}/${TARGET} headers_install

  # Duplicated in musl.
  echo '' > ${crossDir}/${TARGET}/include/asm/sigcontext.h

  if [[ $TARGET == aarch64-* ]]; then
    mkdir -p ${crossDir}/${TARGET}/lib
    ln -s lib64 ${crossDir}/${TARGET}/lib
  fi
}

function binutils() {
  prepare binutils-${BINUTILS_VER} binutils-${BINUTILS_VER} BUILD-cross

  msg 'Configuring toolchain binutils'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
		 --disable-werror || exit 1

  msg 'Compiling toolchain binutils'
  make -j4 || exit 1

  msg 'Installing toolchain binutils'
  make install || exit 1
}

function binutils_win() {
  prepare binutils-${BINUTILS_VER} binutils-${BINUTILS_VER} BUILD-cross-win

  msg 'Configuring toolchain binutils'
  CPP='/usr/bin/cpp' \
    ../configure --host=x86_64-w64-mingw32 --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
                 --disable-werror || exit 1

  msg 'Compiling toolchain binutils'
  make -j4 || exit 1

  msg 'Installing toolchain binutils'
  make install || exit 1
}

function gcc() {
  prepare isl-${ISL_VER} isl-${ISL_VER} BUILD-cross
  prepare gcc-${GCC_VER} gcc-${GCC_VER} BUILD-cross

  # Link isl into GCC source-tree, to simplfy configure command-line.
  ln -sf ${buildDir}/isl-${ISL_VER} ../isl

  msg 'Configuring toolchain GCC'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
		 --enable-languages=c,c++ ${CPU_FLAGS} --disable-static || exit 1

  msg 'Compiling toolchain GCC'
  make -j4 all-gcc || exit 1

  msg 'Installing toolchain GCC'
  make install-strip-gcc || exit 1
}

function gcc_win() {
  prepare isl-${ISL_VER} isl-${ISL_VER} BUILD-cross-win
  prepare gcc-${GCC_VER} gcc-${GCC_VER} BUILD-cross-win

  # Link isl into GCC source-tree, to simplfy configure command-line.
  ln -sf ${buildDir}/isl-${ISL_VER} ../isl

  msg 'Configuring toolchain GCC'
  CPP='/usr/bin/cpp' \
    ../configure --host=x86_64-w64-mingw32 --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
                 --enable-languages=c,c++ ${CPU_FLAGS} --disable-static || exit 1

  msg 'Compiling toolchain GCC'
  make -j4 all-gcc || exit 1

  msg 'Installing toolchain GCC'
  make install-strip-gcc || exit 1
}

# We have a poblem here; libgcc depends on libc, but libc also needs libgcc since GCC generates code
# that call functions from libgcc (e.g. floating-point helper functions). We solve that cyclic
# dependency issue by first compiling a limited libgcc (static only, without supports for threads).
# That bootstrap libgcc suffices to build our libc and after that the fully-functional libgcc.
function libgcc1() {
  prepare gcc-${GCC_VER} gcc-${GCC_VER} BUILD-cross-libgcc1

  msg 'Configuring toolchain bootstrap libgcc'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --target=${TARGET} --prefix=${crossDir} --disable-nls --disable-multilib \
		 --enable-languages=c ${CPU_FLAGS} --disable-shared --disable-threads || exit 1

  msg 'Compiling toolchain bootstrap libgcc'
  make -j4 all-target-libgcc || exit 1

  msg 'Installing toolchain bootstrap libgcc'
  make install-strip-target-libgcc || exit 1
}

function musl() {
  prepare musl-${MUSL_VER} musl-${MUSL_VER} BUILD-cross

  msg 'Configuring toolchain musl'
  CROSS_COMPILE=${crossPrefix} \
    ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --disable-static || exit 1

  msg 'Compiling toolchain musl'
  make -j4 || exit 1

  msg 'Installing toolchain musl'
  make install || exit 1
}

function libgcc() {
  prepare gcc-${GCC_VER} gcc-${GCC_VER} BUILD-cross

  msg 'Compiling toolchain libgcc & libstdc++'
  make -j4 all-target-libgcc all-target-libstdc++-v3 || exit 1

  msg 'Installing toolchain libgcc & libstdc++'
  make install-strip-target-libgcc install-strip-target-libstdc++-v3 || exit 1

  rm -rf ${crossDir}/lib/gcc/${TARGET}/${GCC_VER}/include-fixed
}

function zlib() {
  prepare zlib-${ZLIB_VER} zlib-${ZLIB_VER}

  msg 'Configuring zlib'
  CC=${crossPrefix}gcc \
    ./configure --prefix=${crossDir}/${TARGET}

  msg 'Compiling zlib'
  make -j4 || exit

  msg 'Installing zlib'
  make install || exit 1
}

function libressl() {
  prepare libressl-${LIBRESSL_VER} libressl-${LIBRESSL_VER} BUILD

  msg 'Configuring libressl'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --disable-static || exit 1

  msg 'Compiling libressl'
  make -j4 || exit 1

  msg 'Installing libressl'
  make install || exit 1
}

function libpng() {
  prepare libpng-${LIBPNG_VER} libpng-${LIBPNG_VER} BUILD

  msg 'Configuring libpng'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --disable-static || exit 1

  msg 'Compiling libpng'
  make -j4 || exit

  msg 'Installing libpng'
  make install || exit 1
}

function jpeglib() {
  prepare jpegsrc.v${JPEGLIB_VER} jpeg-${JPEGLIB_VER} BUILD

  msg 'Configuring jpeglib'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --disable-static || exit 1

  msg 'Compiling jpeglib'
  make -j4 || exit 1

  msg 'Installing jpeglib'
  make install || exit 1
}

function freetype() {
  prepare freetype-${FREETYPE_VER} freetype-${FREETYPE_VER} BUILD

  msg 'Configuring freetype'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --disable-static \
	       --without-bzip2 --without-png --without-harfbuzz || exit 1

  msg 'Compiling freetype'
  make -j4 || exit 1

  msg 'Installing freetype'
  make install || exit 1
}

function sdl() {
  prepare SDL-${SDL_VER} SDL-${SDL_VER} BUILD

  cd ..
  sed -i 's/arm-\*/arm-* | aarch64-*/' build-scripts/config.sub
  sed -i 's/-eabi/-*musl/' build-scripts/config.sub
  sed -i 's/\*-\*-linux/*-linux/' configure.in
  ./autogen.sh
  cd BUILD

  msg 'Configuring SDL'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --enable-shared --disable-static \
	       --without-x --disable-pulseaudio --disable-joystick || exit 1

  msg 'Compiling SDL'
  make -j4 || exit 1

  msg 'Installing SDL'
  make install || exit 1
}

function sdl_image() {
  prepare SDL_image-${SDL_IMAGE_VER} SDL_image-${SDL_IMAGE_VER} BUILD

  cd ..
  sed -i 's/arm-\*/arm-* | aarch64-*/' config.sub
  sed -i 's/-eabi/-musl*/' config.sub
  cd BUILD

  msg 'Configuring SDL_image'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --disable-webp --disable-static \
	       --with-sdl-prefix=${crossDir}/${TARGET} || exit 1

  msg 'Compiling SDL_image'
  make -j4 || exit 1

  msg 'Installing SDL_image'
  make install || exit 1
}

function sdl_ttf() {
  prepare SDL_ttf-${SDL_TTF_VER} SDL_ttf-${SDL_TTF_VER} BUILD

  cd ..
  sed -i 's/arm-\*/arm-* | aarch64-*/' config.sub
  sed -i 's/-eabi/-musl*/' config.sub
  sed -i '/noinst_PROGRAMS = showfont$(EXEEXT) glfont$(EXEEXT)/ d' Makefile.in
  cd BUILD

  msg 'Configuring SDL_ttf'
  ../configure --host=${TARGET} --prefix=${crossDir}/${TARGET} --without-x --disable-static \
	       --with-sdl-prefix=${crossDir}/${TARGET} \
	       --with-freetype-prefix=${crossDir}/${TARGET} || exit 1

  msg 'Compiling SDL_ttf'
  make -j4 || exit 1

  msg 'Installing SDL_ttf'
  make install || exit 1
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
  kernelHeaders)
    kernelHeaders
    ;;
  binutils)
    binutils
    ;;
  binutils_win)
    binutils_win
    ;;
  gcc)
    gcc
    ;;
  gcc_win)
    gcc_win
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
  sdl)
    sdl
    ;;
  sdl_image)
    sdl_image
    ;;
  sdl_ttf)
    sdl_ttf
    ;;
  all)
    rm -rf ${crossDir}
    kernelHeaders
    binutils
    gcc
    libgcc1
    musl
    libgcc
    zlib
    libressl
    libpng
    jpeglib
    freetype
    sdl
    sdl_image
    sdl_ttf
    trim
    ;;
esac
