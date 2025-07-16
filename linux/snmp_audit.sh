#!/bin/bash
# Author: Victor Bishop (Heretic) | https://github.com/Heretic312/devsecops-wrappers.git
# Date: 5/2/2025
# Simple script to check for insecure SNMP v1/v2c/v3 configs

CONFIG="/etc/snmp/snmpd.conf"
echo "

▄▖▖ ▖▖  ▖▄▖  ▄▖   ▌▘▗ 
▚ ▛▖▌▛▖▞▌▙▌  ▌▌▌▌▛▌▌▜▘
▄▌▌▝▌▌▝ ▌▌   ▛▌▙▌▙▌▌▐▖
                      

"

# Check if snmpd is installed
if ! command -v snmpd &>/dev/null; then
  echo "SNMP daemon (snmpd) is not installed."
  exit 1
fi

# Check if snmpd service is running
echo -n "Checking snmpd service status: "
if systemctl is-active --quiet snmpd; then
  echo "Running"
else
  echo "Not running"
fi

# Look for insecure SNMP v1/v2c community strings
echo "Scanning $CONFIG for insecure SNMPv1/v2c settings..."
if grep -E "^\s*(rocommunity|rwcommunity)" "$CONFIG"; then
  echo "Oh Shit! Insecure SNMP v1/v2c settings found!"
else
  echo "No SNMP v1/v2c community strings detected."
fi

# Check for SNMPv3 users
echo "Checking for SNMPv3 user definitions..."
if grep -q "^createUser" "$CONFIG"; then
  echo "SNMPv3 users configured."
else
  echo "No SNMPv3 users found."
fi

# Check which interfaces snmpd is listening on
echo "Checking SNMP listening interfaces..."
LISTEN=$(ss -tulpn | grep snmpd)
if echo "$LISTEN" | grep -q "0.0.0.0"; then
  echo "SNMP is listening on all interfaces (0.0.0.0). Consider binding to localhost or trusted IPs."
else
  echo "SNMP is not listening on all interfaces."
fi

# Done
echo "SNMP audit complete."
