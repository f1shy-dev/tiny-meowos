#!/bin/bash

# Set up work directory
WORKDIR=/workspaces/codespaces-blank/moo
INITRAMFS_ROOT=$WORKDIR/initramfs
mkdir -p $INITRAMFS_ROOT/{bin,sbin,etc,proc,sys,dev,usr/{bin,sbin}}

# Compile your shell
cd $WORKDIR
gcc -c -nostdlib shell.S -o shell.S.o
gcc -c -nostdlib -fno-builtin shell.c -o shell.c.o
ld -static -o shell shell.c.o shell.S.o
cp shell $INITRAMFS_ROOT/bin/

# Download and compile BusyBox if not already present
if [ ! -f $WORKDIR/busybox ]; then
    cd $WORKDIR
    wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    tar xjf busybox-1.36.1.tar.bz2
    cd busybox-1.36.1
    
    # Configure BusyBox for static build with minimal features
    make defconfig
    # Modify configuration to build statically
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    
    # Build BusyBox
    make -j$(nproc)
    
    # Copy BusyBox to our bin directory
    cp busybox $INITRAMFS_ROOT/bin/
    cp busybox $WORKDIR/busybox
else
    cp $WORKDIR/busybox $INITRAMFS_ROOT/bin/
fi

# Create symlinks for BusyBox applets
cd $INITRAMFS_ROOT/bin
for applet in ash cat cp ls mkdir mount umount sh echo grep vi find; do
    ln -sf busybox $applet
done

# Create an init script
cat > $INITRAMFS_ROOT/init << 'EOF'
#!/bin/sh
# Mount essential filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Set up PATH
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Execute your shell or drop to BusyBox shell
if [ -x /bin/shell ]; then
    exec /bin/shell
else
    exec /bin/sh
fi
EOF

# Make init executable
chmod +x $INITRAMFS_ROOT/init

# Create the initramfs
cd $INITRAMFS_ROOT
find . | cpio -H newc -o | gzip > $WORKDIR/init.cpio

# Build the kernel with our initramfs
cd /workspaces/codespaces-blank/linux
make isoimage FDARGS="initrd=/init.cpio" FDINITRD=$WORKDIR/init.cpio