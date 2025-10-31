#!/usr/bin/env bash
set -euo pipefail

# scan_multi_concurrent.sh
#
# Author: Victor Bishop (Heretic312)
# Date: 10/29/2025 
# About: 
#    Multi-Subnet Scanner that produces a CSV with ip, hostname, mac, vendor.
# 
# Key Features:
#    Accepts subnets with an argument or environment variable, else fallback to default subnet.
#    Passing one or more subnets on the command line (./scan_multi_concurrent.sh 192.168.1.0/24 10.0.0.0/16)
#    Comma-separated SUBNETS environment variable (SUBNETS="10.0.0.0/8,192.168.1.0/24" ./scan_multi_concurrent.sh)
#    File listed in SUBNET_FILE where each line is a subnet/CIDR
#    Validates each subnet with Python's "ipaddress"
#    Saves per-subnet XML results for accurate parsing of MAC/vendor/hostnames.
#    Consolidates all results into internal_ips_YYYY-MM-DD_HH-MM-SS.csv.
#    Includes a short note about the MAC/vendor limitation.
#       
# Usage examples:
#   ./scan_multi_concurrent.sh 192.168.1.0/24 10.0.0.0/24
#   SUBNETS="192.168.1.0/24,10.0.0.0/24" ./scan_multi_concurrent.sh
#   SUBNET_FILE=subnets.txt CONCURRENCY=6 ./scan_multi_concurrent.sh
#
# Output:
#   internal_ips_<timestamp>.csv   (columns: ip,hostname,mac,vendor)
#   per-subnet XML files used for parsing
#
# Notes:
# - Requires: nmap, python3, xargs (for parallel). If you prefer GNU parallel, you can modify.
# - MAC & vendor info is only available for hosts on the same L2 (local VLAN). Remote routed hosts won't show MACs.
# - Run as root to get MAC/vendor on local networks: sudo ./scan_multi_concurrent.sh 192.168.1.0/24 192.168.2.0/24
# - Increase concurrency by settings CONCURRENCY: CONCURRENCY=8 ./scan_multi_concurrent.sh ...


# Default values
DEFAULT_SUBNET="10.2.1.110/14"
CONCURRENCY="${CONCURRENCY:-4}"   # default number of parallel nmap jobs
WORKDIR="${WORKDIR:-./scan_results}"

# gather subnets into an array
subnets=()
if [ "$#" -gt 0 ]; then
  for a in "$@"; do subnets+=("$a"); done
elif [ -n "${SUBNETS:-}" ]; then
  IFS=',' read -r -a tmp <<< "${SUBNETS}"
  for s in "${tmp[@]}"; do subnets+=("$(echo "$s" | xargs)"); done
elif [ -n "${SUBNET_FILE:-}" ]; then
  while IFS= read -r line; do
    line="$(echo "$line" | xargs)"   # trim whitespace
    [ -z "$line" ] && continue
    subnets+=("$line")
  done < "$SUBNET_FILE"
else
  subnets+=("$DEFAULT_SUBNET")
fi

# checks
for cmd in python3 nmap xargs; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command '$cmd' not found in PATH." >&2
    exit 2
  fi
done

timestamp="$(date +%F_%H-%M-%S)"
mkdir -p "$WORKDIR"

# canonicalize subnets (use python ipaddress)
canonicalize() {
  local raw="$1"
  python3 - <<PY
import sys, ipaddress
try:
    net = ipaddress.ip_network(sys.argv[1], strict=False)
    print(str(net))
except Exception:
    sys.exit(1)
PY "$raw"
}

# build a list of canonical subnets to scan
canonical_subnets=()
for s in "${subnets[@]}"; do
  if can=$(canonicalize "$s") ; then
    canonical_subnets+=("$can")
  else
    echo "WARNING: invalid subnet/CIDR '$s' - skipping." >&2
  fi
done

if [ ${#canonical_subnets[@]} -eq 0 ]; then
  echo "No valid subnets to scan. Exiting." >&2
  exit 1
fi

echo "Starting concurrent scans (concurrency=$CONCURRENCY). Workdir: $WORKDIR"
echo "Subnets:"
for s in "${canonical_subnets[@]}"; do printf " - %s\n" "$s"; done

# Create a commands file for xargs; each line runs one nmap scan producing XML
cmdfile="$(mktemp)"
trap 'rm -f "$cmdfile"' EXIT

for can in "${canonical_subnets[@]}"; do
  safe="${can//\//-}"
  xmlout="${WORKDIR}/nmap_${safe}_${timestamp}.xml"
  # use -sn for ping/host discovery and -oX for XML; use --privileged behavior (run as root to get MAC info on L2)
  # Note: running as root yields better ARP discovery and MAC vendor info on local networks.
  printf "nmap -sn %s -oX %s\n" "$can" "$xmlout" >> "$cmdfile"
done

# run the commands in parallel using xargs -P
# xargs will take each line and run it via sh -c
echo "Launching scans..."
cat "$cmdfile" | xargs -I CMD -P "$CONCURRENCY" sh -c 'echo "CMD: $0"; $0' 

echo "All nmap scans finished. Parsing XML files to CSV..."

# Python parser: read all xml files in WORKDIR with the timestamp and produce CSV
csv_out="internal_ips_${timestamp}.csv"

python3 - <<PYTHON
import xml.etree.ElementTree as ET
import glob, csv, os, sys, re

workdir = os.path.abspath("${WORKDIR}")
timestamp = "${timestamp}"
pattern = os.path.join(workdir, f"nmap_*_{timestamp}.xml")
files = sorted(glob.glob(pattern))
out = "${csv_out}"

# helper to normalize strings
def clean(s):
    if s is None:
        return ""
    return re.sub(r'\\s+', ' ', s.strip())

rows = []
for f in files:
    try:
        tree = ET.parse(f)
    except Exception as e:
        # skip bad xml files
        continue
    root = tree.getroot()
    # iterate hosts
    for host in root.findall('host'):
        ip = ""
        hostname = ""
        mac = ""
        vendor = ""
        # addresses
        for addr in host.findall('address'):
            addrtype = addr.get('addrtype')
            addrval = addr.get('addr')
            if addrtype == 'ipv4' or addrtype == 'ip':
                ip = addrval
            elif addrtype == 'mac':
                mac = addrval
                vendor = addr.get('vendor') or vendor
        # hostnames (take first if present)
        hs = host.find('hostnames')
        if hs is not None:
            h = hs.find('hostname')
            if h is not None:
                hostname = h.get('name') or hostname
        # sanity: if no ip, try to find in status/ports lines (rare)
        if not ip:
            # fallback: search for address/@addr with ipv4
            for addr in host.findall('address'):
                if addr.get('addrtype') in ('ipv4','ip'):
                    ip = addr.get('addr')
        rows.append({
            'ip': clean(ip),
            'hostname': clean(hostname),
            'mac': clean(mac),
            'vendor': clean(vendor),
        })

# dedupe rows by ip (keep first)
seen = set()
deduped = []
for r in rows:
    key = r['ip']
    if not key:
        continue
    if key in seen:
        continue
    seen.add(key)
    deduped.append(r)

# write csv
with open(out, 'w', newline='') as csvfile:
    w = csv.DictWriter(csvfile, fieldnames=['ip','hostname','mac','vendor'])
    w.writeheader()
    for r in sorted(deduped, key=lambda x: tuple(int(p) if p.isdigit() else 0 for p in x['ip'].split('.'))):
        w.writerow(r)

print(f"Wrote CSV: {out}")
print(f"Parsed {len(deduped)} unique IP(s) from {len(files)} XML file(s).")
PYTHON

echo ""
echo "Completed. CSV: $csv_out"
echo ""
echo "IMPORTANT NOTES:"
echo " - MAC/vendor columns are only available when scanning on the same L2 (local VLAN)."
echo " - Run this script as root (sudo) if you want ARP-based discovery and MAC/vendor info on local networks."
