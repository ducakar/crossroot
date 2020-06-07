MUSL_VER       := 1.2.0
MUSL_URL       := "https://www.musl-libc.org/releases/musl-$(MUSL_VER).tar.gz"
MUSL_ARCHIVE   := download/musl-$(MUSL_VER).tar.gz
MUSL_SRC_DIR   := src/musl-$(MUSL_VER)
MUSL_BUILD_DIR := build/musl-$(MUSL_VER)
MUSL_CONF      := --host=$(TOOLCHAIN_TARGET) \
                  --prefix=/usr \
                  --disable-static

musl-clean:
	rm -rf $(MUSL_BUILD_DIR)

musl-download: $(MUSL_ARCHIVE)

musl-src: $(MUSL_SRC_DIR)

musl-build: $(MUSL_BUILD_DIR)

musl-install: $(MUSL_BUILD_DIR)
	$(call log,installing musl)
	cd $(MUSL_BUILD_DIR) && make install DESTDIR=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET)

$(MUSL_ARCHIVE):
	$(call log,downloading musl)
	mkdir -p download
	wget -q $(MUSL_URL) -O $(MUSL_ARCHIVE)

$(MUSL_SRC_DIR): $(MUSL_ARCHIVE)
	$(call log,unpacking musl)
	mkdir -p src
	tar xf $(MUSL_ARCHIVE) -C src
	touch $(MUSL_SRC_DIR)

$(MUSL_BUILD_DIR): $(MUSL_SRC_DIR)
	$(call log,building musl)
	mkdir -p $(MUSL_BUILD_DIR)
	cd $(MUSL_BUILD_DIR) && CROSS_COMPILE=$(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_TARGET)- CC= ../../$(MUSL_SRC_DIR)/configure $(MUSL_CONF)
	cd $(MUSL_BUILD_DIR) && make -j8
