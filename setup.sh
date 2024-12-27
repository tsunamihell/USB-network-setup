#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


echo "Running as root..."
sleep 2
clear

# Check internet connectivity
ping -c 1 google.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}No internet connection. Please check your network settings.${NC}"
    exit 1
fi

# Retry opkg update up to 5 times
TRIES=0
while [ ${TRIES} -lt 5 ]; do
    opkg update && break
    let TRIES++
    echo "Retrying opkg update (${TRIES}/5)..."
    sleep 2
done

if [ ${TRIES} -eq 5 ]; then
    echo -e "${RED}Package update failed after 5 attempts.${NC}"
    exit 1
fi

# Replace OpenWRT repository mirror if needed
REPO_URL="https://downloads.openwrt.org/releases/23.05.0"
ALTERNATE_REPO="http://mirror2.openwrt.org/releases/23.05.0"

wget --spider "${REPO_URL}" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Switching to alternate repository...${NC}"
    sed -i "s|${REPO_URL}|${ALTERNATE_REPO}|g" /etc/opkg/distfeeds.conf
fi

# Install required USB internet packages
opkg install kmod-usb-net-rndis
opkg install kmod-usb-net-cdc-ether
opkg install usbmuxd libimobiledevice usbutils

# Configure usbmuxd
usbmuxd -v
sed -i -e "\$i usbmuxd" /etc/rc.local

# Configure network interfaces
uci set network.wan.ifname="usb0"
uci set network.wan6.ifname="usb0"
uci commit network
/etc/init.d/network restart

# Script completed

echo -e "${GREEN}USB internet setup completed successfully.${NC}"
