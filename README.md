# MeowOS

A minimal, custom operating system with a simple shell.

## Project Structure

- `/` - Main project directory
  - `/shell` - Custom shell implementation
  - `/initramfs` - Generated directory for initial ramdisk
  - `Makefile` - Main build system
  - `kernel.config` - Optional Linux kernel configuration

## Building

### Prerequisites

- GCC and development tools
- Linux kernel source code in `../linux` (relative to the meowos directory)
- Internet connection (for downloading BusyBox)
- QEMU for testing

### Build Commands

```bash
# Build everything (shell, busybox, initramfs, kernel)
make all

# Build just the shell
make shell

# Clean build artifacts
make clean

# Clean everything including downloaded components
make distclean

# Run the OS in QEMU
make run
```

## Linux Kernel - Git Submodule

```bash
# From the meowos parent directory
git submodule add --depth=1 https://github.com/torvalds/linux.git linux
git submodule update --init --depth=1 linux
cd linux
git checkout v6.1  # or your desired stable version
```
