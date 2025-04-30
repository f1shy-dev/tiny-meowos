# Libraries Makefile for TinyMeowOS

# Paths
LIB_ROOT := $(shell pwd)
CONFIG_FILE := $(LIB_ROOT)/libs.config

# Default target
.PHONY: all
all: prepare_libraries

# Target to copy libraries from host system
.PHONY: prepare_libraries
prepare_libraries:
	@echo "=== Preparing libraries ==="
	@echo "Source: Host system ($(HOST_LIB_DIR))"
	@echo "Destination: $(INITRAMFS_DIR)"
	@echo "Configuration: $(CONFIG_FILE)"
	@echo
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "Error: Configuration file not found: $(CONFIG_FILE)"; \
		exit 1; \
	fi
	@if [ ! -d "$(INITRAMFS_DIR)" ]; then \
		echo "Error: Destination directory not found: $(INITRAMFS_DIR)"; \
		exit 1; \
	fi
	@while IFS= read -r line || [ -n "$$line" ]; do \
		case "$$line" in \
			\#*|"") continue ;; \
		esac; \
		if [ -n "$$line" ]; then \
			lib_name=$$(echo "$$line" | cut -d'|' -f1 | xargs); \
			host_path=$$(echo "$$line" | cut -d'|' -f2 | xargs); \
			dest_path=$$(echo "$$line" | cut -d'|' -f3 | xargs); \
			echo "Processing $$lib_name..."; \
			if [ ! -f "$$host_path" ]; then \
				echo "  Warning: Source file not found: $$host_path"; \
				continue; \
			fi; \
			mkdir -p "$(INITRAMFS_DIR)/$$(dirname "$$dest_path")"; \
			cp -v "$$host_path" "$(INITRAMFS_DIR)/$$dest_path"; \
		fi; \
	done < "$(CONFIG_FILE)"
	@echo
	@echo "=== Library copy complete ==="

# Target to clean libraries
.PHONY: clean
clean:
	@echo "=== Cleaning libraries ==="
	@echo "This will not remove libraries from the initramfs"
	@echo "To remove libraries from the initramfs, run 'make clean_initramfs'"

# Target to clean libraries from the initramfs
.PHONY: clean_initramfs
clean_initramfs:
	@echo "=== Cleaning libraries from initramfs ==="
	@if [ -f "$(CONFIG_FILE)" ]; then \
		while IFS= read -r line || [ -n "$$line" ]; do \
			case "$$line" in \
				\#*|"") continue ;; \
			esac; \
			if [ -n "$$line" ]; then \
				dest_path=$$(echo "$$line" | cut -d'|' -f3 | xargs); \
				if [ -n "$$dest_path" ] && [ -f "$(INITRAMFS_DIR)/$$dest_path" ]; then \
					echo "Removing $(INITRAMFS_DIR)/$$dest_path"; \
					rm -f "$(INITRAMFS_DIR)/$$dest_path"; \
				fi; \
			fi; \
		done < "$(CONFIG_FILE)"; \
	fi
