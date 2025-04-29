#!/bin/sh

# Define color code for grey
GREY='\033[0;37m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color
CYAN='\033[1;36m'
BOLD='\033[1m'

# /bin/busybox clear
echo -e "${GREY}[+] Starting init script...${NC}"

# Try mounting proc
echo -e "${GREY}[+] Mounting filesystems...${NC}"
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
/bin/busybox mount -t devtmpfs devtmpfs /dev 

# echo -e "${GREY}[+] Binding framebuffer console...${NC}"
# for (( i = 0; i < 16; i++))
# do
#   if test -x /sys/class/vtconsole/vtcon$i; then
#       if [ `cat /sys/class/vtconsole/vtcon$i/name | grep -c "frame buffer"` \
#            = 1 ]; then
#         echo Unbinding vtcon$i
#         echo 1 > /sys/class/vtconsole/vtcon$i/bind
#       fi
#   fi
# done


echo -e "${GREY}[+] Supressing system/kernel messages...${NC}"
echo 1 > /proc/sys/kernel/printk
echo 1 > /proc/sys/kernel/panic

echo -e "${GREY}[+] Setting up terminal...${NC}"
export TERM=linux

echo -e ""
echo -e "${CYAN}  /\_/\  ${NC}"
echo -e "${CYAN} ( o.o ) ${NC}"
echo -e "${CYAN}  > ^ <  ${NC}"
echo -e "${PURPLE}Welcome to MeowOS! Purr-fect system is ready.${NC}"

echo -e ""

/bin/busybox uname -a
echo -e ""
/bin/busybox setsid /bin/cttyhack /bin/sh
# exec /bin/busybox sh