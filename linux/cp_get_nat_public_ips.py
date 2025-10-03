#!/usr/bin/env python3
"""
Author: Victor Bishop
Date:  10/3/2025
cp_get_nat_public_ips.py
Extracts unique public IPs from Check Point NAT rules using mgmt_cli as root user.
You may need to run dos2unix on the file for conversion 
"""

import subprocess
import json
import sys
import os

# ---------- Configuration ----------
NAT_LAYER_NAME = "Standard"   # Update this to your NAT layer name
SESSION_FILE = "session.json"
# -----------------------------------

def run_mgmt_cli(args):
    if not os.path.isfile(SESSION_FILE):
        print(f"[!] Session file '{SESSION_FILE}' not found.")
        sys.exit(1)
    cmd = ["mgmt_cli"] + args + ["-s", SESSION_FILE, "--format", "json"]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        print(f"[!] mgmt_cli error: {p.stderr.strip()}")
        sys.exit(1)
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError:
        print("[!] Failed to parse JSON output from mgmt_cli:")
        print(p.stdout)
        sys.exit(1)

def login():
    cmd = ["mgmt_cli", "login", "-r", "true", "--format", "json"]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        print(f"[!] Login failed: {p.stderr.strip()}")
        sys.exit(1)
    try:
        login_response = json.loads(p.stdout)
        sid = login_response.get("sid")
        if not sid:
            raise ValueError("No session ID in login response")
        with open(SESSION_FILE, "w") as f:
            json.dump({"sid": sid}, f)
    except Exception as e:
        print(f"[!] Failed to process login response: {e}")
        print(p.stdout)
        sys.exit(1)

def logout():
    if os.path.isfile(SESSION_FILE):
        subprocess.run(["mgmt_cli", "logout", "-s", SESSION_FILE], capture_output=True)
        os.remove(SESSION_FILE)

def is_public_ip(ip):
    if not ip:
        return False
    if ip.startswith("127.") or ip.startswith("169.254.") or ip.startswith("10.") or ip.startswith("192.168."):
        return False
    if ip.startswith("172."):
        try:
            second = int(ip.split(".")[1])
            if 16 <= second <= 31:
                return False
        except:
            return False
    return True

def main():
    print("[*] Logging into Check Point API...")
    login()

    print(f"[*] Fetching NAT rulebase from layer '{NAT_LAYER_NAME}'...")
    out = run_mgmt_cli(["show-nat-rulebase", "name", NAT_LAYER_NAME])
    rule_entries = out.get("rulebase", [])

    public_ips = set()

    for rule in rule_entries:
        nat = rule.get("nat-settings", {})
        orig_dst = rule.get("original-destination", {})
        xlate_dst = nat.get("translated-destination", {})

        for ip_obj in (orig_dst, xlate_dst):
            ip = ip_obj.get("ipv4-address")
            if is_public_ip(ip):
                public_ips.add(ip)

    print(f"\n[*] Found {len(public_ips)} unique public IPs:")
    for ip in sorted(public_ips):
        print(ip)

    print("\n[*] Logging out...")
    logout()

if __name__ == "__main__":
    main()

