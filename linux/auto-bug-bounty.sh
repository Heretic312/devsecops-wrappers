#!/bin/bash
# Bug Bounty Automation Script
# Author: Victor Bishop (heretic312)
# Description: Automates reconnaissance and vulnerability scanning for bug bounty hunting.
# Required Tools: subfinder, httpx, nmap, ffuf, amass, waybackurls, nuclei
### **Customization**
# Modify the wordlist path in the fuzzing section.
# Add or replace tools based on your preferences (e.g., using `assetfinder` instead of `subfinder`).
# Adjust Nuclei templates to focus on specific vulnerabilities.

# Ensure required tools are installed
REQUIRED_TOOLS=("subfinder" "httpx" "nmap" "ffuf" "amass" "waybackurls" "nuclei")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "$tool is not installed. Please install it before running this script."
        exit 1
    fi
done

# Get target domain from user input
read -p "Enter target domain: " TARGET

# Create a directory for the target to organize outputs
mkdir -p "$TARGET"
cd "$TARGET" || exit

echo "[+] Starting bug bounty automation for $TARGET"

# Step 1: Subdomain Enumeration
echo "[+] Enumerating subdomains..."
subfinder -d "$TARGET" -o subdomains.txt
amass enum -passive -d "$TARGET" >> subdomains.txt
sort -u subdomains.txt -o subdomains.txt

# Step 2: Checking for live hosts
echo "[+] Checking for live hosts..."
cat subdomains.txt | httpx -silent -o live_hosts.txt

# Step 3: Scanning for open ports
echo "[+] Scanning for open ports..."
nmap -iL live_hosts.txt -T4 -oN nmap_scan.txt

# Step 4: Directory fuzzing with FFUF
echo "[+] Running directory fuzzing..."
mkdir -p fuzzing_results
while read -r host; do
    ffuf -u "$host/FUZZ" -w /usr/share/wordlists/dirb/common.txt -o "fuzzing_results/${host//[:\/]/_}.json"
done < live_hosts.txt

# Step 5: Gathering URLs from Wayback Machine
echo "[+] Fetching URLs from Wayback Machine..."
cat subdomains.txt | waybackurls > wayback_urls.txt

# Step 6: Scanning for vulnerabilities with Nuclei
echo "[+] Running vulnerability scans with Nuclei..."
nuclei -l live_hosts.txt -t /path/to/nuclei-templates/ -o nuclei_results.txt

# Final Output Summary
echo "[+] Automation complete. Results saved in the $TARGET directory."
echo "Subdomains found: $(wc -l < subdomains.txt)"
echo "Live hosts: $(wc -l < live_hosts.txt)"
echo "Nmap scan results: nmap_scan.txt"
echo "Fuzzing results stored in the fuzzing_results/ directory."
echo "Wayback URLs saved in wayback_urls.txt"
echo "Nuclei scan results saved in nuclei_results.txt"
