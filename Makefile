# MeowOS Main Makefile
# Coordinates the build process for the entire MeowOS system

# Cross-compilation setup
CROSS_COMPILE := x86_64-linux-gnu-
# CROSS_COMPILE := i686-linux-gnu-
export CROSS_COMPILE

# ARCH := i386
ARCH := x86_64
export ARCH

# Variables
IS_TINY := 1
SHELL_DIR := shell
INIT_DIR := init
WORKDIR := $(CURDIR)
INITRAMFS_ROOT := $(WORKDIR)/initramfs
LINUX_DIR_REL := ./linux
LINUX_DIR := $(realpath $(LINUX_DIR_REL))
BUSYBOX_DIR := $(WORKDIR)/busybox
BUSYBOX_CONFIG := $(BUSYBOX_DIR)/.config
BUSYBOX_BINARY := $(BUSYBOX_DIR)/busybox
INITRAMFS_ARCHIVE := $(WORKDIR)/init.cpio

# List of busybox applets to link
BUSYBOX_APPLETS := ash cat cp ls mkdir mount umount sh echo grep vi find clear \
                    rm touch chmod chown ps top free df du dmesg uname hostname \
                    kill killall sleep ping ifconfig ip route netstat wget tar \
                    gzip gunzip unzip sed awk cpio sync reboot poweroff insmod \
                    rmmod lsmod modprobe sort cttyhack udhcpc udhcpd stty setsid

# Sentinel file for busybox symlinks
BUSYBOX_SYMLINKS_SENTINEL := $(INITRAMFS_ROOT)/.busybox_symlinks

.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'
# IMPORTANT: The line above must be indented by (at least one) 
#            *actual TAB character* - *spaces* do *not* work.


.PHONY: menuconfig_kernel
menuconfig_kernel: kernel_config
	cd $(LINUX_DIR) && ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) menuconfig
	@if [ -f $(LINUX_DIR)/.config ]; then \
		echo "Saving kernel config..."; \
		if [ "$(IS_TINY)" = "1" ]; then \
			cp $(LINUX_DIR)/.config $(WORKDIR)/kernel.config.tiny; \
		else \
			cp $(LINUX_DIR)/.config $(WORKDIR)/kernel.config.def; \
		fi \
	fi

.PHONY: menuconfig_busybox
menuconfig_busybox: $(BUSYBOX_DIR)/.config
	cd $(BUSYBOX_DIR) && $(MAKE) menuconfig
	@if [ -f $(BUSYBOX_DIR)/.config ]; then \
		echo "Saving BusyBox config..."; \
		cp $(BUSYBOX_DIR)/.config $(WORKDIR)/busybox.config; \
	fi

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

# Build the init program
.PHONY: init
init:
	$(MAKE) -C $(INIT_DIR) clean
	$(MAKE) -C $(INIT_DIR)

# Install shell to initramfs
$(INITRAMFS_ROOT)/bin/shell: shell dirs
	cp $(SHELL_DIR)/shell $@

# Install init to initramfs and copy init.sh
$(INITRAMFS_ROOT)/sbin/init: init dirs
	cp $(INIT_DIR)/init $@
	cp $(INIT_DIR)/init.sh $(INITRAMFS_ROOT)/sbin/init.sh
	chmod +x $@
	chmod +x $(INITRAMFS_ROOT)/sbin/init.sh
	# Verify init file is executable in target env
	file $@

$(INITRAMFS_ROOT)/shallow: dirs
	@echo "Copying files from initramfs-shallow to initramfs..."
	@cp -af $(WORKDIR)/initramfs-shallow/* $(INITRAMFS_ROOT)/


$(BUSYBOX_DIR)/.config:
	@if [ ! -d $(BUSYBOX_DIR) ]; then \
		echo "BusyBox directory not found. Please run 'git submodule init' and 'git submodule update'"; \
		exit 1; \
	fi
	@if [ -f $(WORKDIR)/busybox.config ]; then \
		echo "Using custom BusyBox config..."; \
		cp $(WORKDIR)/busybox.config $(BUSYBOX_DIR)/.config; \
		# Ensure cross-compiler is set correctly even in custom config; \
		sed -i 's/^CONFIG_CROSS_COMPILER_PREFIX=.*/CONFIG_CROSS_COMPILER_PREFIX="$(subst /,\/,$(CROSS_COMPILE))"/' $(BUSYBOX_DIR)/.config; \
	else \
		echo "No custom BusyBox config found. Generating default config..."; \
		cd $(BUSYBOX_DIR) && $(MAKE) defconfig; \
		sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' $(BUSYBOX_DIR)/.config; \
		# Set cross-compilation in BusyBox config; \
		sed -i 's/^CONFIG_CROSS_COMPILER_PREFIX=.*/CONFIG_CROSS_COMPILER_PREFIX="$(subst /,\/,$(CROSS_COMPILE))"/' $(BUSYBOX_DIR)/.config; \
		sed -i 's/^CONFIG_EXTRA_LDFLAGS=""/CONFIG_EXTRA_LDFLAGS="-L/usr/$(ARCH)-linux-gnu/lib"/' $(BUSYBOX_DIR)/.config; \
	fi

$(BUSYBOX_BINARY): $(BUSYBOX_DIR)/.config
	cd $(BUSYBOX_DIR) && $(MAKE) -j$(shell nproc) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)

# Copy busybox binary directly to initramfs without intermediate copy
$(INITRAMFS_ROOT)/bin/busybox: $(BUSYBOX_BINARY) dirs
	cp $(BUSYBOX_BINARY) $@

# Target for creating BusyBox symlinks
$(BUSYBOX_SYMLINKS_SENTINEL): $(INITRAMFS_ROOT)/bin/busybox
	@cd $(INITRAMFS_ROOT)/bin && \
	  for applet in $(BUSYBOX_APPLETS); do \
	    ln -sf busybox $$applet; \
	  done
	@touch $@

# Target for creating the initramfs archive
# Depends on the essential components being present
$(INITRAMFS_ARCHIVE): $(INITRAMFS_ROOT)/bin/shell $(INITRAMFS_ROOT)/bin/busybox $(BUSYBOX_SYMLINKS_SENTINEL) $(INITRAMFS_ROOT)/sbin/init $(INITRAMFS_ROOT)/shallow
	@echo "Creating initramfs archive..."
	cd $(INITRAMFS_ROOT) && find . | cpio -H newc -o > $(INITRAMFS_ARCHIVE)

# Copy kernel config
.PHONY: kernel_config
kernel_config:
	@if [ "$(IS_TINY)" = "1" ]; then \
		echo "Copying tiny kernel config..."; \
		cp kernel.config.tiny $(LINUX_DIR)/.config; \
	else \
		echo "Copying default kernel config..."; \
		cp kernel.config.def $(LINUX_DIR)/.config; \
	fi

# Target for building the kernel ISO
.PHONY: kernel_iso
kernel_iso: $(INITRAMFS_ARCHIVE) kernel_config
	@echo "Building kernel ISO image..."
	cd $(LINUX_DIR) && \
	ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -j$(shell nproc) isoimage FDARGS="initrd=/init.cpio" FDINITRD=$(INITRAMFS_ARCHIVE)

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
	cd $(BUSYBOX_DIR) && $(MAKE) clean
	rm -f $(INITRAMFS_ARCHIVE)
	rm -rf $(INITRAMFS_ROOT)

.PHONY: distclean
distclean: clean
	# Optionally clear kernel build artifacts if needed
	cd $(LINUX_DIR) && ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) clean 
	cd $(BUSYBOX_DIR) && ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) clean