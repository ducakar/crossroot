TARGET='arm-linux-gnueabi'
TARGET_BM='arm-linux-eabi'
BINUTILS_VER='2.26'
ISL_VER='0.15'
GCC_VER='5.3.0'
MUSL_VER='1.1.14'

requiredExes=(wget tar gzip bzip2 make gcc ccache)

rootDir=`pwd`
srcDir=${rootDir}/src
buildDir=${rootDir}/build
crossDir=${rootDir}/cross
crossPrefix=${crossDir}/bin/${TARGET}-
crossPrefixBM=${crossDir}/bin/${TARGET_BM}-

function msg() {
  echo -e "\e[1;32m=== ${@} ===\e[0m"
}

function sanityCheck() {
  if [[ `dirname ${0}` != . ]]; then
    echo "You must run ${0} from its home directory."
    exit 1
  fi

  for exe in ${requiredExes[@]}; do
    if [[ ! -f /usr/bin/${exe} ]]; then
      echo "Missing /usr/bin/${exe}"
      exit 1
    fi
  done
}

function fetchPkg() {
  wget -c -nc -P ${srcDir} ${@}
}

function fetch() {
  msg 'Fetching'
  fetchPkg "http://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.bz2"
  fetchPkg "ftp://gd.tuwien.ac.at/gnu/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2"
  fetchPkg "http://isl.gforge.inria.fr/isl-${ISL_VER}.tar.bz2"
  fetchPkg "http://www.musl-libc.org/releases/musl-${MUSL_VER}.tar.gz"
  msg 'Fetched everything'
}

function clean() {
  rm -rf ${buildDir}/*/BUILD* ${crossDir}
}

function stripBinaries() {
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

# Unpack source to build directory and go to build/<package>/<buildSubdir>.
function prepare() {
  name=${1}
  package=${srcDir}/${1}*

  if [[ -d ${buildDir}/${name} ]]; then
    msg "Already unpacked ${name}"

    rm -Rf ${buildDir}/${name}/${2}
  else
    msg "Unpacking ${name}"

    mkdir -p ${buildDir} || exit 1
    tar xf ${package}* -C ${buildDir} || exit 1
  fi

  # Create the build directory and go to it.
  mkdir -p ${buildDir}/${name}/${2} && cd ${buildDir}/${name}/${2}
}

function binutils() {
  prepare binutils-${BINUTILS_VER} BUILD

  msg 'Configuring binutils'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
  ../configure --prefix=${crossDir} --target=${TARGET} --disable-nls --disable-multilib \
	       --enable-lto || exit 1

  msg 'Compiling binutils'
  make -j4 || exit 1

  msg 'Installing binutils'
  make install || exit 1
}

function gcc() {
  prepare isl-${ISL_VER} BUILD
  prepare gcc-${GCC_VER} BUILD

  # Link isl into GCC source-tree, to simplfy configure command-line.
  ln -sf ${buildDir}/isl-${ISL_VER} ../isl

  msg 'Configuring GCC'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --prefix=${crossDir} --target=${TARGET} --disable-nls --disable-multilib \
		 --enable-languages=c --disable-static || exit 1

  msg 'Compiling GCC'
  make -j4 all-gcc || exit 1

  msg 'Installing GCC'
  make install-gcc || exit 1
}

# We have a poblem here; libgcc depends on libc, but libc also needs libgcc since GCC generates code
# that call functions from libgcc (e.g. floating-point helper functions). We solve that cyclic 
# dependency issue by first compiling a limited libgcc (static only, without supports for threads).
# Bootstrap libgcc is used to build libc and afeter that we can build a fully-functional libgcc.
function libgcc1() {
  prepare gcc-${GCC_VER} BUILD-libgcc1

  msg 'Configuring bootstrap libgcc'
  CC='ccache gcc' CXX='ccache g++' CPP='/usr/bin/cpp' \
    ../configure --prefix=${crossDir} --target=${TARGET} --disable-nls --disable-multilib \
		 --enable-languages=c --disable-threads --disable-shared || exit 1

  msg 'Compiling bootstrap libgcc'
  make -j4 all-target-libgcc || exit 1

  msg 'Installing bootstrap libgcc'
  make install-target-libgcc || exit 1
}

function musl() {
  prepare musl-${MUSL_VER} BUILD

  msg 'Configuring musl'
  CROSS_COMPILE=${crossPrefix} \
    ../configure --prefix=${crossDir}/${TARGET} --host=${TARGET} --disable-static || exit 1

  msg 'Compiling musl'
  make -j4 || exit 1

  msg 'Installing musl'
  make install || exit 1
}

function libgcc() {
  prepare gcc-${GCC_VER} BUILD-libgcc

  msg 'Copying BUILD directory from GCC to continue building in it'
  cp -a ../BUILD/* .

  msg 'Compiling final libgcc'
  make -j4 all-target-libgcc || exit 1

  msg 'Installing final libgcc'
  make install-target-libgcc || exit 1
}

sanityCheck

case ${1} in
  fetch)
    fetch
    ;;
  clean)
    clean
    ;;
  strip)
    stripBinaries
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
    clean
    binutils
    gcc
    libgcc1
    musl
    libgcc
    stripBinaries
    ;;
esac
