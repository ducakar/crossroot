GCC_VER           := 10.1.0
GCC_URL           := "ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz"
GCC_ARCHIVE       := download/gcc-$(GCC_VER).tar.xz
GCC_SRC_DIR       := src/gcc-$(GCC_VER)
GCC_BUILD_DIR     := build/gcc-$(GCC_VER)
LIBGCC0_BUILD_DIR := build/libgcc0-$(GCC_VER)
LIBGCC_BUILD_DIR  := build/libgcc-$(GCC_VER)
GCC_CONF          := --target=$(TOOLCHAIN_TARGET) --prefix=$(TOOLCHAIN_DIR) \
                     --with-sysroot=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET) \
                     --with-build-sysroot=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET) \
                     --disable-nls --disable-multilib --with-system-zlib \
                     --with-linker-hash=gnu --enable-languages=c \
                     --disable-static $(GCC_CONF_EXTRA)
LIBGCC0_CONF      := --target=$(TOOLCHAIN_TARGET) --prefix=$(TOOLCHAIN_DIR) \
                     --disable-nls --disable-multilib --with-system-zlib \
                     --with-linker-hash=gnu --enable-languages=c \
                     --disable-shared --disable-threads $(GCC_CONF_EXTRA)

GMP_VER        := 6.2.0
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

ISL_VER        := 0.22
ISL_URL        := "http://isl.gforge.inria.fr/isl-$(ISL_VER).tar.xz"
ISL_ARCHIVE    := download/isl-$(ISL_VER).tar.xz
ISL_SRC_DIR    := src/isl-$(ISL_VER)

gcc-clean:
	rm -rf $(GCC_BUILD_DIR)

libgcc0-clean:
	rm -rf $(LIBGCC0_BUILD_DIR)

libgcc-clean:
	rm -rf $(LIBGCC_BUILD_DIR)

gcc-download: $(GCC_ARCHIVE) $(GMP_ARCHIVE) $(MPFR_ARCHIVE) $(ISL_ARCHIVE)

gcc-src: $(GCC_SRC_DIR)

gcc-build: $(GCC_BUILD_DIR)

gcc-install: $(GCC_BUILD_DIR)
	$(call log,installing gcc)
	cd $(GCC_BUILD_DIR) && make install-strip-gcc
	# rm -rf ${TOOLCHAIN_DIR}/lib/gcc/${TOOLCHAIN_TARGET}/${GCC_VER}/include-fixed

libgcc0-build: $(LIBGCC0_BUILD_DIR)

libgcc0-install: $(LIBGCC0_BUILD_DIR)
	$(call log,installing bootstrap libgcc)
	cd $(LIBGCC0_BUILD_DIR) && make install-strip-target-libgcc

libgcc-build: $(GCC_BUILD_DIR)

libgcc-install: $(GCC_BUILD_DIR)
	$(call log,building libgcc)
	cd $(GCC_BUILD_DIR) && make -j8 all-target-libgcc
	$(call log,installing libgcc)
	cd $(GCC_BUILD_DIR) && make install-strip-target-libgcc

libstdc++-install: $(GCC_BUILD_DIR)
	$(call log,installing libstdc++)
	cd $(GCC_BUILD_DIR) && make -j8 all-target-libstdc++-v3
	cd $(GCC_BUILD_DIR) && make install-strip-target-libstdc++-v3

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

$(LIBGCC0_BUILD_DIR): $(GCC_SRC_DIR)
	$(call log,building bootstrap libgcc)
	mkdir -p $(LIBGCC0_BUILD_DIR)
	cd $(LIBGCC0_BUILD_DIR) && ../../$(GCC_SRC_DIR)/configure $(LIBGCC0_CONF)
	cd $(LIBGCC0_BUILD_DIR) && make -j8 all-target-libgcc
