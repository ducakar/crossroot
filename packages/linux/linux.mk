LINUX_VER       := 5.4.42
LINUX_URL       := "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$(LINUX_VER).tar.xz"
LINUX_ARCHIVE   := download/linux-$(LINUX_VER).tar.xz
LINUX_SRC_DIR   := src/linux-$(LINUX_VER)
LINUX_BUILD_DIR := build/linux-$(LINUX_VER)

linux-clean:
	rm -rf $(LINUX_BUILD_DIR)

linux-download: $(LINUX_ARCHIVE)

linux-src: $(LINUX_SRC_DIR)

linux-headers-install: $(LINUX_SRC_DIR)
	$(call log,installing linux headers)
	cd $(LINUX_SRC_DIR) && make headers_install INSTALL_HDR_PATH=$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TARGET)/usr

$(LINUX_ARCHIVE):
	$(call log,downloading linux)
	mkdir -p download
	wget -q $(LINUX_URL) -O $(LINUX_ARCHIVE)

$(LINUX_SRC_DIR): $(LINUX_ARCHIVE)
	$(call log,unpacking linux)
	mkdir -p src
	tar xf $(LINUX_ARCHIVE) -C src
	touch $(LINUX_SRC_DIR)
