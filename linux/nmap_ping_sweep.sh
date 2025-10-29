#!/bin/bash
#  Continuous Internal IP Scanning Script (schedule with Cron and Diff results)
#  Author:  Victor Bishop (Heretic312)
#  Date:  10/29/2025
#  nmap -sn = "ping sweep" -oG = "Output to file.txt"
#  Modify subnet="" to match your network
 
subnet=""
timestamp=$(date +%F_%H-%M)
nmap -sn $subnet -oG "internal_ips_$timestamp.txt"