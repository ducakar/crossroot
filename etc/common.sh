requiredExes=(wget tar gzip bzip2 xz cmake make ccache gcc mono)

rootDir=`pwd`
srcDir=${rootDir}/src
buildDir=${rootDir}/build
crossDir=${rootDir}/cross
crossPrefix=${crossDir}/bin/${TARGET}-
targetDir=${rootDir}/target
imagesDir=${rootDir}/images

export PKG_CONFIG_PATH=${crossDir}/${TARGET}/lib/pkgconfig
export PKG_CONFIG_LIBDIR=${crossDir}/${TARGET}/lib

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

function clean() {
  rm -rf ${buildDir}/*/BUILD*
}

# Unpack source to build directory and go to build/<package>/<buildSubdir>.
function prepare() {
  name=${2}
  package=${srcDir}/${1}*

  if [[ -d ${buildDir}/${name} ]]; then
    msg "Already unpacked ${name}"
  else
    msg "Unpacking ${name}"

    mkdir -p ${buildDir} || exit 1
    tar xf ${package}* -C ${buildDir} || exit 1
  fi

  # Create the build directory and go to it.
  mkdir -p ${buildDir}/${name}/${3} && cd ${buildDir}/${name}/${3}
}

sanityCheck

export PATH=$PATH:${crossDir}/bin
