# MeowOS Main Makefile
# Coordinates the build process for the entire MeowOS system

# Cross-compilation setup
CROSS_COMPILE := x86_64-linux-gnu-
export CROSS_COMPILE

# Variables
SHELL_DIR := shell
WORKDIR := $(CURDIR)
INITRAMFS_ROOT := $(WORKDIR)/initramfs
LINUX_DIR_REL := ./linux
LINUX_DIR := $(realpath $(LINUX_DIR_REL))
BUSYBOX_VERSION := 1.36.1
BUSYBOX_URL := https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_TARBALL := $(WORKDIR)/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_SRCDIR := $(WORKDIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_CONFIG := $(BUSYBOX_SRCDIR)/.config
BUSYBOX_BINARY := $(BUSYBOX_SRCDIR)/busybox
INITRAMFS_ARCHIVE := $(WORKDIR)/init.cpio

# List of busybox applets to link
BUSYBOX_APPLETS := ash cat cp ls mkdir mount umount sh echo grep vi find

# Sentinel file for busybox symlinks
BUSYBOX_SYMLINKS_SENTINEL := $(INITRAMFS_ROOT)/.busybox_symlinks

.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'
# IMPORTANT: The line above must be indented by (at least one) 
#            *actual TAB character* - *spaces* do *not* work.

# Default target
.PHONY: all
all: kernel_iso

# Target to create necessary directories
.PHONY: dirs
dirs:
	@mkdir -p $(INITRAMFS_ROOT)/bin
	@mkdir -p $(INITRAMFS_ROOT)/sbin
	@mkdir -p $(INITRAMFS_ROOT)/etc
	@mkdir -p $(INITRAMFS_ROOT)/proc
	@mkdir -p $(INITRAMFS_ROOT)/sys
	@mkdir -p $(INITRAMFS_ROOT)/dev
	@mkdir -p $(INITRAMFS_ROOT)/usr/bin
	@mkdir -p $(INITRAMFS_ROOT)/usr/sbin

# Build the shell
.PHONY: shell
shell:
	$(MAKE) -C $(SHELL_DIR) clean
	$(MAKE) -C $(SHELL_DIR)

# Install shell to initramfs
$(INITRAMFS_ROOT)/bin/shell: shell dirs
	cp $(SHELL_DIR)/shell $@

# Targets for BusyBox
$(BUSYBOX_TARBALL):
	wget $(BUSYBOX_URL) -O $@

$(BUSYBOX_SRCDIR)/.unpacked: $(BUSYBOX_TARBALL)
	tar xjf $< -C $(WORKDIR)
	@touch $@

$(BUSYBOX_CONFIG): $(BUSYBOX_SRCDIR)/.unpacked
	cd $(BUSYBOX_SRCDIR) && $(MAKE) defconfig
	sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' $@
	# Set cross-compilation in BusyBox config
	sed -i 's/^CONFIG_CROSS_COMPILER_PREFIX=""/CONFIG_CROSS_COMPILER_PREFIX="$(subst /,\/,$(CROSS_COMPILE))"/' $@
	# Add extra library path for static libraries
	echo 'CONFIG_EXTRA_LDFLAGS="-L/usr/x86_64-linux-gnu/lib"' >> $@

$(BUSYBOX_BINARY): $(BUSYBOX_CONFIG)
	cd $(BUSYBOX_SRCDIR) && $(MAKE) -j$(shell nproc)

# Copy busybox binary to WORKDIR (cache) and initramfs
$(WORKDIR)/busybox: $(BUSYBOX_BINARY)
	cp $< $@

$(INITRAMFS_ROOT)/bin/busybox: $(WORKDIR)/busybox dirs
	cp $< $@

# Target for creating BusyBox symlinks
$(BUSYBOX_SYMLINKS_SENTINEL): $(INITRAMFS_ROOT)/bin/busybox
	@cd $(INITRAMFS_ROOT)/bin && \
	  for applet in $(BUSYBOX_APPLETS); do \
	    ln -sf busybox $$applet; \
	  done
	@touch $@

# Target for creating the init script
$(INITRAMFS_ROOT)/init: dirs
	cp $(WORKDIR)/init.sh $@
	chmod +x $@

# Target for creating the initramfs archive
# Depends on the essential components being present
$(INITRAMFS_ARCHIVE): $(INITRAMFS_ROOT)/bin/shell $(INITRAMFS_ROOT)/bin/busybox $(BUSYBOX_SYMLINKS_SENTINEL) $(INITRAMFS_ROOT)/init
	@echo "Creating initramfs archive..."
	cd $(INITRAMFS_ROOT) && find . | cpio -H newc -o | gzip > $(INITRAMFS_ARCHIVE)

# Copy kernel config
.PHONY: kernel_config
kernel_config:
	@if [ -f kernel.config ]; then \
		echo "Copying kernel config..."; \
		cp kernel.config $(LINUX_DIR)/.config; \
	else \
		echo "No kernel.config found - using existing .config in kernel directory"; \
	fi

# Target for building the kernel ISO
.PHONY: kernel_iso
kernel_iso: $(INITRAMFS_ARCHIVE) kernel_config
	@echo "Building kernel ISO image..."
	cd $(LINUX_DIR) && \
	ARCH=x86_64 CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -j$(shell nproc) isoimage FDARGS="initrd=/init.cpio" FDINITRD=$(INITRAMFS_ARCHIVE)

# Run QEMU with the built ISO
.PHONY: run
run:
	@if [ -f $(LINUX_DIR)/arch/x86/boot/image.iso ]; then \
		qemu-system-x86_64 -cdrom $(LINUX_DIR)/arch/x86/boot/image.iso -enable-kvm; \
	else \
		echo "ISO image not found. Run 'make' first."; \
		exit 1; \
	fi

# Clean targets
.PHONY: clean
clean:
	$(MAKE) -C $(SHELL_DIR) clean
	rm -f $(INITRAMFS_ARCHIVE)
	rm -rf $(INITRAMFS_ROOT)

.PHONY: distclean
distclean: clean
	rm -rf $(BUSYBOX_SRCDIR) $(BUSYBOX_TARBALL)
	rm -f $(WORKDIR)/busybox
	# Optionally clear kernel build artifacts if needed
	cd $(LINUX_DIR) && ARCH=x86_64 CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) clean 