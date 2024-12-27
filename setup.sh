#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


echo "Running as root..."
sleep 2
clear




# Install required USB internet packages
opkg install kmod-usb-net-rndis
opkg install kmod-usb-net-huawei-cdc-ncm
opkg install kmod-usb-net-cdc-ncm kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset
opkg install kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb-net-cdc-ether kmod-usb2
opkg install kmod-usb-net-ipheth usbmuxd libimobiledevice usbutils
opkg install kmod-usb-net-qmi-wwan uqmi
opkg install kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan
opkg install usb-modeswitch usb-modeswitch-data
opkg install kmod-usb-net-rndis kmod-usb-net-asix kmod-usb-net-cdc-acm kmod-usb-net-rtl8152
opkg install kmod-usb-serial-ch341 kmod-usb-serial-pl2303

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
