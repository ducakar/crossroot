BINUTILS_VER       := 2.34
BINUTILS_URL       := "http://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VER).tar.xz"
BINUTILS_ARCHIVE   := download/binutils-$(BINUTILS_VER).tar.xz
BINUTILS_SRC_DIR   := src/binutils-$(BINUTILS_VER)
BINUTILS_BUILD_DIR := build/binutils-$(BINUTILS_VER)
BINUTILS_CONF      := --target=$(TOOLCHAIN_TARGET) --prefix=$(TOOLCHAIN_DIR) \
                      --disable-nls --disable-multilib --with-system-zlib \
                      $(BINUTILS_CONF_EXTRA)

binutils-clean:
	rm -rf $(BINUTILS_BUILD_DIR)

binutils-download: $(BINUTILS_ARCHIVE)

binutils-build: $(BINUTILS_BUILD_DIR)

binutils-install: $(BINUTILS_BUILD_DIR)
	$(call log,Installing binutils)
	cd $(BINUTILS_BUILD_DIR) && make install-strip

$(BINUTILS_ARCHIVE):
	$(call log,Downloading binutils)
	mkdir -p download
	wget -q $(BINUTILS_URL) -O $(BINUTILS_ARCHIVE)

$(BINUTILS_SRC_DIR): $(BINUTILS_ARCHIVE)
	$(call log,Unpacking binutils)
	mkdir -p src
	tar xf $(BINUTILS_ARCHIVE) -C src
	touch $(BINUTILS_SRC_DIR)

$(BINUTILS_BUILD_DIR): $(BINUTILS_SRC_DIR)
	$(call log,Building binutils)
	mkdir -p $(BINUTILS_BUILD_DIR)
	cd $(BINUTILS_BUILD_DIR) && ../../$(BINUTILS_SRC_DIR)/configure $(BINUTILS_CONF)
	cd $(BINUTILS_BUILD_DIR) && make -j8
