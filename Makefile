TOOLCHAIN_DIR       := $(shell pwd)/toolchain
TOOLCHAIN_TARGET    := arm-linux-gnueabihf

BINUTILS_CONF_EXTRA :=
GCC_CONF_EXTRA      := --with-cpu=generic-armv7-a --with-fpu=neon --with-float=hard

export CC  = /usr/bin/ccache /usr/bin/gcc
export CXX = /usr/bin/ccache /usr/bin/g++
export CPP = /usr/bin/cpp

define log
	@printf '\e[1;32m=== %s ===\e[0m\n' "$(1)"
endef

all: linux-headers-install binutils-install gcc-install libgcc0-install \
	musl-install libgcc-install

clean: linux-clean binutils-clean gcc-clean libgcc0-clean libgcc-clean \
	musl-clean

distclean: clean
	rm -rf toolchain

include packages/linux/linux.mk
include packages/binutils/binutils.mk
include packages/gcc/gcc.mk
include packages/musl/musl.mk
