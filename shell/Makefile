# Shell Makefile
# Build the shell component for MeowOS - Cross-compilation from ARM64 to x86-64

# Cross-compiler toolchain prefix
CROSS_COMPILE := x86_64-linux-gnu-

# Tools
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld

# Source files
S_SRC := shell.S
C_SRC := shell.c
S_OBJ := shell.S.o
C_OBJ := shell.c.o
TARGET := shell

# Compiler and Linker Flags
CFLAGS := -c -nostdlib -fno-builtin -Wall
ASFLAGS := -c -nostdlib
LDFLAGS := -static

# Default target
.PHONY: all
all: $(TARGET)

# The order of compilation matters!
# First compile assembly, then C, then link
$(TARGET): $(S_OBJ) $(C_OBJ)
	$(LD) $(LDFLAGS) -o $@ $(C_OBJ) $(S_OBJ)

# Assembly first
$(S_OBJ): $(S_SRC)
	$(CC) $(ASFLAGS) $< -o $@

# Then C code 
$(C_OBJ): $(C_SRC)
	$(CC) $(CFLAGS) $< -o $@

# Clean target
.PHONY: clean
clean:
	rm -f $(S_OBJ) $(C_OBJ) $(TARGET) 