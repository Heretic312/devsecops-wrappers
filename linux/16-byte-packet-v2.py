# Send 16-byte packets using Scapy for manual network tests
# Author:  Victor Bishop (Heretic)  |  https://github.com/Heretic312/devsecops-wrappers.git
# Date:  5/8/2025

from scapy.all import *

# Get user input
target_ip = input("Enter target IP address: ")
target_port = int(input("Enter target port: "))
tcp_flags = input("Enter TCP flags (e.g., S for SYN, R for RST, A for ACK, etc.): ")

# Construct IP and TCP layers
ip = IP(dst=target_ip)
tcp = TCP(sport=RandShort(), dport=target_port, flags=tcp_flags, seq=1000)
payload = b"A" * 16  # 16-byte payload

# Create and send packet
packet = ip / tcp / Raw(load=payload)
send(packet)

# Optionally send an RST packet (only if user included 'S' in flags, as example)
if "S" in tcp_flags:
    tcp_rst = TCP(sport=RandShort(), dport=target_port, flags="R", seq=1000)
    rst_packet = ip / tcp_rst
    send(rst_packet)
