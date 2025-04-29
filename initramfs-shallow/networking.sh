#! /bin/sh

GREY='\033[0;37m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Bring up network interface eth0
if [ -e /sys/class/net/eth0 ]; then
    echo -e "${GREY}[+] Bringing up network interface ${BOLD}eth0${NC}...${NC}"
    /bin/busybox ifconfig eth0 up
    /bin/busybox udhcpc -i eth0
    /bin/busybox ip link set eth0 up
    /bin/busybox ip addr add 10.0.2.15/24 dev eth0
    /bin/busybox ip route add default via 10.0.2.2 dev eth0
    echo -e "${GREEN}[+] Network interface eth0 is up with default route via 10.0.2.2${NC}"
else
    echo -e "${RED}[-] Network interface eth0 not found${NC}"
fi

# Bring up network interface wlan0
if [ -e /sys/class/net/wlan0 ]; then
    echo -e "${GREY}[+] Bringing up network interface ${BOLD}wlan0${NC}...${NC}"
    /bin/busybox ifconfig wlan0 up
    /bin/busybox udhcpc -i wlan0
    /bin/busybox ip link set wlan0 up
    /bin/busybox ip addr add 10.0.2.15/24 dev wlan0
    /bin/busybox ip route add default via 10.0.2.2 dev wlan0
    echo -e "${GREEN}[+] Network interface wlan0 is up with default route via 10.0.2.2${NC}"
else
    echo -e "${RED}[-] Network interface wlan0 not found${NC}"
fi

