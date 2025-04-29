#!/bin/sh

# Define color code for grey
GREY='\033[0;37m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color
CYAN='\033[1;36m'

/bin/busybox clear
echo -e "${GREY}[+] Starting init script...${NC}"

# Try mounting proc
echo -e "${GREY}[+] Mounting filesystems...${NC}"
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
/bin/busybox mount -t devtmpfs devtmpfs /dev 


echo -e "${GREY}[+] Supressing system/kernel messages...${NC}"
echo 1 > /proc/sys/kernel/printk
echo 1 > /proc/sys/kernel/panic

echo -e ""
echo -e "${CYAN}  /\_/\  ${NC}"
echo -e "${CYAN} ( o.o ) ${NC}"
echo -e "${CYAN}  > ^ <  ${NC}"
echo -e "${PURPLE}Welcome to MeowOS! Purr-fect system is ready.${NC}"

echo -e ""
echo -e "${GREY}[+] Dropping to shell...${NC}"

/bin/busybox uname -a
echo -e ""
exec /bin/busybox sh