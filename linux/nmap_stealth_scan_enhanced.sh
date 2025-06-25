#!/bin/bash

# Enhanced Stealthy Nmap Scan Wrapper with CIDR, Proxychains, and Output Reporting
# Author: Victor Bishop (Heretic312)
# Usage: ./nmap_stealth_scan.sh <target_ip_or_cidr> [port_range]
# Example: ./nmap_stealth_scan.sh 10.10.10.0/24 "22,80,443"

command -v nmap >/dev/null 2>&1 || { echo >&2 "Nmap is not installed."; exit 1; }
command -v proxychains >/dev/null 2>&1 || { echo >&2 "Proxychains is not installed."; exit 1; }

TARGET="$1"
PORTS="$2"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <target_ip_or_cidr> [port_range]"
    exit 1
fi

if [[ -z "$PORTS" ]]; then
    PORTS="22,80,443"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGDIR="nmap_stealth_logs_$TIMESTAMP"
mkdir -p "$LOGDIR"
CSV_FILE="$LOGDIR/scan_results.csv"
JSON_FILE="$LOGDIR/scan_results.json"

echo "IP,Open Ports" > "$CSV_FILE"
echo "[" > "$JSON_FILE"

echo "[*] Starting stealth scan on $TARGET with ports $PORTS"
echo "[*] Logs and results will be saved in $LOGDIR"

# Get list of IPs to scan from CIDR
HOSTS=$(nmap -n -sL "$TARGET" | awk '/Nmap scan report/{print $NF}')

for IP in $HOSTS; do
    LOGFILE="$LOGDIR/nmap_stealth_$IP.log"
    echo "[*] Scanning $IP..."
    proxychains nmap \
        -sT \
        -Pn \
        --disable-arp-ping \
        -T1 \
        --max-retries 1 \
        --scan-delay 5s \
        --host-timeout 10m \
        --randomize-hosts \
        --data-length 50 \
        -n \
        -p "$PORTS" \
        "$IP" -oN "$LOGFILE" > /dev/null

    OPEN_PORTS=$(grep "^\d\+/tcp\s\+open" "$LOGFILE" | awk '{print $1}' | paste -sd "," -)
    echo "$IP,$OPEN_PORTS" >> "$CSV_FILE"

    echo "  {" >> "$JSON_FILE"
    echo "    \"ip\": \"$IP\"," >> "$JSON_FILE"
    echo "    \"open_ports\": [$(echo "$OPEN_PORTS" | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')]" >> "$JSON_FILE"
    echo "  }," >> "$JSON_FILE"

    echo "[*] Scan of $IP complete. Open ports: $OPEN_PORTS"
done

# Remove trailing comma and close JSON array
sed -i '$ s/},/}/' "$JSON_FILE"
echo "]" >> "$JSON_FILE"

echo "[*] All scans completed."
echo "[*] CSV output: $CSV_FILE"
echo "[*] JSON output: $JSON_FILE"
