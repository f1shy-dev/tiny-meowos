#!/bin/sh
# Mount essential filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Set up PATH
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Execute our shell or drop to BusyBox shell
if [ -x /bin/shell ]; then
    exec /bin/shell
else
    exec /bin/sh
fi 