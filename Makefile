TOOLCHAIN_DIR    := $(shell pwd)/toolchain
TOOLCHAIN_TARGET := arm-linux-musleabihf

export CC  = /usr/bin/ccache /usr/bin/gcc
export CXX = /usr/bin/ccache /usr/bin/g++
export CPP = /usr/bin/cpp

define log
	@printf '\e[1;32m=== %s ===\e[0m\n' "$(1)"
endef

all: linux-headers-install binutils-install gcc-install-gcc \
	gcc-install-libgcc1 musl-install gcc-install-libgcc \
	gcc-install-libstdc++

clean: binutils-clean gcc-clean linux-clean musl-clean

distclean: clean
	rm -rf toolchain

include packages/linux/linux.mk
include packages/binutils/binutils.mk
include packages/gcc/gcc.mk
include packages/musl/musl.mk
