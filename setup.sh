#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking root privileges...${NC}"
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root.${NC}"
   exit 1
fi

echo -e "${YELLOW}Updating package lists...${NC}"
if ! opkg update; then
    echo -e "${RED}Failed to update package lists. Check your internet connection.${NC}"
    exit 1
fi

# Install required USB internet packages
PACKAGES=(
    kmod-usb-net-rndis kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-ncm
    kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset
    kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb-net-cdc-ether kmod-usb2
    kmod-usb-net-ipheth usbmuxd libimobiledevice usbutils
    kmod-usb-net-qmi-wwan uqmi
    kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan
    usb-modeswitch usb-modeswitch-data
    kmod-usb-net-asix kmod-usb-net-cdc-acm kmod-usb-net-rtl8152
    kmod-usb-serial-ch341 kmod-usb-serial-pl2303
)

echo -e "${YELLOW}Installing required packages...${NC}"
for pkg in "${PACKAGES[@]}"; do
    if ! opkg list-installed | grep -q "^$pkg "; then
        echo -e "${GREEN}Installing $pkg...${NC}"
        if ! opkg install "$pkg"; then
            echo -e "${RED}Failed to install $pkg. Continuing with the next package.${NC}"
        fi
    else
        echo -e "${YELLOW}$pkg is already installed. Skipping.${NC}"
    fi
done

# Configure usbmuxd
echo -e "${YELLOW}Configuring usbmuxd...${NC}"
if command -v usbmuxd &> /dev/null; then
    usbmuxd -v
    if ! grep -q "usbmuxd" /etc/rc.local; then
        echo "usbmuxd" >> /etc/rc.local
    fi
else
    echo -e "${RED}usbmuxd is not installed or executable.${NC}"
fi

# Configure network interfaces
echo -e "${YELLOW}Configuring network interfaces...${NC}"
if ip link show | grep -q "usb0"; then
    uci set network.wan.ifname="usb0"
    uci set network.wan6.ifname="usb0"
    if uci commit network; then
        echo -e "${GREEN}Network configuration updated.${NC}"
    else
        echo -e "${RED}Failed to update network configuration.${NC}"
    fi
else
    echo -e "${RED}usb0 interface not found. Ensure your USB internet device is connected.${NC}"
fi

# Restart network
echo -e "${YELLOW}Restarting network...${NC}"
if /etc/init.d/network restart; then
    echo -e "${GREEN}Network restarted successfully.${NC}"
else
    echo -e "${RED}Failed to restart network. Check logs for errors.${NC}"
fi

echo -e "${GREEN}USB internet setup completed successfully.${NC}"

