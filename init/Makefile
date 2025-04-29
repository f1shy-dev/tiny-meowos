# Init Makefile
# Build the static init component for MeowOS

# Cross-compiler toolchain prefix
CROSS_COMPILE := x86_64-linux-gnu-

# Tools
AS := $(CROSS_COMPILE)as
LD := $(CROSS_COMPILE)ld

# Source and target files
SRC := init.S
OBJ := init.o
TARGET := init

# Linker Flags
LDFLAGS := -static

# Default target
.PHONY: all
all: $(TARGET)

# Compile assembly to object file
$(OBJ): $(SRC)
	$(AS) -o $@ $<

# Link object file to executable
$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $<

# Clean target
.PHONY: clean
clean:
	rm -f $(OBJ) $(TARGET) 