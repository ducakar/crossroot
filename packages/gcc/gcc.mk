GCC_VER        := 9.2.0
GCC_URL        := "ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz"
GCC_ARCHIVE    := download/gcc-$(GCC_VER).tar.xz
GCC_SRC_DIR    := src/gcc-$(GCC_VER)
GCC_BUILD_DIR  := build/gcc-$(GCC_VER)
GCC_BUILD1_DIR := build/gcc1-$(GCC_VER)
GCC_CONF       := --target=arm-linux-musleabihf --prefix=$(TOOLCHAIN_DIR) \
                  --with-system-zlib --disable-nls --disable-multilib \
                  --with-sysroot=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET) \
                  --with-build-sysroot=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET) \
                  --with-cpu=generic-armv7-a --with-fpu=neon --with-float=hard \
                  --with-linker-hash=gnu --enable-languages=c,c++ \
                  --disable-static
GCC_CONF1      := --target=arm-linux-musleabihf --prefix=$(TOOLCHAIN_DIR) \
                  --with-system-zlib --disable-nls --disable-multilib \
                  --with-build-sysroot=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET) \
                  --with-linker-hash=gnu --enable-languages=c \
                  --with-cpu=generic-armv7-a --with-fpu=neon --with-float=hard \
                  --disable-shared --disable-threads

GMP_VER        := 6.1.2
GMP_URL        := "https://ftp.gnu.org/gnu/gmp/gmp-$(GMP_VER).tar.xz"
GMP_ARCHIVE    := download/gmp-$(GMP_VER).tar.xz
GMP_SRC_DIR    := src/gmp-$(GMP_VER)

MPFR_VER       := 4.0.2
MPFR_URL       := "https://www.mpfr.org/mpfr-current/mpfr-$(MPFR_VER).tar.xz"
MPFR_ARCHIVE   := download/mpfr-$(MPFR_VER).tar.xz
MPFR_SRC_DIR   := src/mpfr-$(MPFR_VER)

MPC_VER        := 1.1.0
MPC_URL        := "https://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VER).tar.gz"
MPC_ARCHIVE    := download/mpc-$(MPC_VER).tar.gz
MPC_SRC_DIR    := src/mpc-$(MPC_VER)

ISL_VER        := 0.21
ISL_URL        := "http://isl.gforge.inria.fr/isl-$(ISL_VER).tar.xz"
ISL_ARCHIVE    := download/isl-$(ISL_VER).tar.xz
ISL_SRC_DIR    := src/isl-$(ISL_VER)

gcc-clean:
	rm -rf $(GCC_BUILD_DIR)
	rm -rf $(GCC_BUILD1_DIR)

gcc-download: $(GCC_ARCHIVE) $(GMP_ARCHIVE) $(MPFR_ARCHIVE) $(ISL_ARCHIVE)

gcc-src: $(GCC_SRC_DIR)

gcc-build-gcc: $(GCC_BUILD_DIR)

gcc-install-gcc: $(GCC_BUILD_DIR)
	$(call log,installing gcc)
	cd $(GCC_BUILD_DIR) && make install-strip-gcc

gcc-build-libgcc1: $(GCC_BUILD1_DIR)

gcc-install-libgcc1: $(GCC_BUILD1_DIR)
	$(call log,installing bootstrap libgcc)
	cd $(GCC_BUILD1_DIR) && make install-strip-target-libgcc

gcc-build-libgcc: $(GCC_BUILD_DIR)
	$(call log,building libgcc)
	cd $(GCC_BUILD_DIR) && make -j8 all-target-libgcc

gcc-install-libgcc: gcc-build-libgcc
	$(call log,installing libgcc)
	cd $(GCC_BUILD_DIR) && make install-strip-target-libgcc
	rm -rf ${TOOLCHAIN_DIR}/lib/gcc/${TOOLCHAIN_TARGET}/${GCC_VER}/include-fixed

gcc-build-libstdc++: $(GCC_BUILD_DIR)
	$(call log,building libstdc++)
	cd $(GCC_BUILD_DIR) && make -j8 all-target-libstdc++-v3

gcc-install-libstdc++: gcc-build-libstdc++
	$(call log,installing libstdc++)
	cd $(GCC_BUILD_DIR) && make install-strip-target-libstdc++-v3
	rm -rf ${TOOLCHAIN_DIR}/lib/gcc/${TOOLCHAIN_TARGET}/${GCC_VER}/include-fixed

$(GCC_ARCHIVE):
	$(call log,downloading gcc)
	mkdir -p download
	wget $(GCC_URL) -O $(GCC_ARCHIVE)
	touch $(GCC_ARCHIVE)

$(GMP_ARCHIVE):
	$(call log,downloading gmp)
	mkdir -p download
	wget $(GMP_URL) -O $(GMP_ARCHIVE)

$(MPFR_ARCHIVE):
	$(call log,downloading mpfr)
	mkdir -p download
	wget $(MPFR_URL) -O $(MPFR_ARCHIVE)

$(MPC_ARCHIVE):
	$(call log,downloading mpc)
	mkdir -p download
	wget $(MPC_URL) -O $(MPC_ARCHIVE)

$(ISL_ARCHIVE):
	$(call log,downloading isl)
	mkdir -p download
	wget $(ISL_URL) -O $(ISL_ARCHIVE)

$(GCC_SRC_DIR): $(GCC_ARCHIVE) $(GMP_SRC_DIR) $(MPFR_SRC_DIR) $(MPC_SRC_DIR) $(ISL_SRC_DIR)
	$(call log,unpacking gcc)
	mkdir -p src
	tar xf $(GCC_ARCHIVE) -C src
	touch $(GCC_SRC_DIR)
	ln -sf ../gmp-$(GMP_VER) $(GCC_SRC_DIR)/gmp
	ln -sf ../mpfr-$(MPFR_VER) $(GCC_SRC_DIR)/mpfr
	ln -sf ../mpc-$(MPC_VER) $(GCC_SRC_DIR)/mpc
	ln -sf ../isl-$(ISL_VER) $(GCC_SRC_DIR)/isl

$(GMP_SRC_DIR): $(GMP_ARCHIVE)
	$(call log,unpacking gmp)
	mkdir -p src
	tar xf $(GMP_ARCHIVE) -C src
	touch $(GMP_SRC_DIR)

$(MPFR_SRC_DIR): $(MPFR_ARCHIVE)
	$(call log,unpacking mpfr)
	mkdir -p src
	tar xf $(MPFR_ARCHIVE) -C src
	touch $(MPFR_SRC_DIR)

$(MPC_SRC_DIR): $(MPC_ARCHIVE)
	$(call log,unpacking mpc)
	mkdir -p src
	tar xf $(MPC_ARCHIVE) -C src
	touch $(MPC_SRC_DIR)

$(ISL_SRC_DIR): $(ISL_ARCHIVE)
	$(call log,unpacking isl)
	mkdir -p src
	tar xf $(ISL_ARCHIVE) -C src
	touch $(ISL_SRC_DIR)

$(GCC_BUILD_DIR): $(GCC_SRC_DIR)
	$(call log,building gcc)
	mkdir -p $(GCC_BUILD_DIR)
	cd $(GCC_BUILD_DIR) && ../../$(GCC_SRC_DIR)/configure $(GCC_CONF)
	cd $(GCC_BUILD_DIR) && make -j8 all-gcc

$(GCC_BUILD1_DIR): $(GCC_SRC_DIR)
	$(call log,building bootstrap libgcc)
	mkdir -p $(GCC_BUILD1_DIR)
	cd $(GCC_BUILD1_DIR) && ../../$(GCC_SRC_DIR)/configure $(GCC_CONF1)
	cd $(GCC_BUILD1_DIR) && make -j8 all-target-libgcc
