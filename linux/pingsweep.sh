#!/bin/bash
#
# ./pingsweep.sh
#
# Author: Victor Bishop (Heretic312)
# Date: 10/31/2025
#
# About:
#     This scans networks.txt with Nmap, tries TCP pings if ICMP fails, and produces inventory.csv with IP plus method.
# 
# Usage:
#    Make a file networks.txt listing each routed subnet you want to scan:
#    10.0.10.0/24
#    10.0.20.0/24
#    192.168.50.0/24
#
# Notes:
#    Replace default .txt and .csv names as needed
nets="networks.txt"
out="inventory.csv"
echo "ip,method" > $out

# ICMP sweep
nmap -sn -iL $nets -oG - | awk '/Up$/{print $2",icmp"}' >> $out

# TCP fallback for networks with no hits (optional)
nmap -sn -PS22,80,443 -iL $nets -oG tcpfallback.gnmap
awk '/Up$/{print $2",tcp"}' tcpfallback.gnmap >> $out

# dedupe
sort -u $out -o $out
