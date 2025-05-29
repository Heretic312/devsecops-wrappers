#!/bin/bash

# Script Name: ssh_harden.sh
# Description: SSH hardening script for Debian 12 (Bookworm) based on https://www.sshaudit.com/hardening_guides.html#debian_12
# Author: Victor Bishop | https://github.com/Heretic312/devsecops-wrappers
# Version: 1.1
# Usage: sudo ./ssh_harden.sh
# Notes: Adjust SSH_PORT as needed if not using port 22

SSH_PORT=22  # Change this to your SSH port if not using 22

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Function to regenerate SSH host keys
regenerate_ssh_keys() {
    read -p "WARNING: This will DELETE and REGENERATE SSH host keys. Continue? (y/n): " confirm
    [[ $confirm != [yY] ]] && echo "Cancelled." && return

    echo "Regenerating SSH host keys..."
    rm -f /etc/ssh/ssh_host_*
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

    # Clean existing HostKey lines to prevent duplication
    sed -i '/^HostKey \/etc\/ssh\/ssh_host_/d' /etc/ssh/sshd_config
    echo -e "HostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config

    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli

    echo "SSH host keys regenerated successfully."
}

# Function to apply SSH hardening configuration
apply_ssh_hardening() {
    echo "Applying SSH hardening configuration..."
    cat > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf <<EOF
# SSH Hardening as per sshaudit.com guide for Debian 12

KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr

MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

RequiredRSASize 3072

CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256

GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-

HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256

PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256
EOF

    systemctl restart ssh
    echo "SSH hardening configuration applied successfully."
}

# Function to configure iptables rules
configure_firewall() {
    echo "Installing and configuring iptables firewall rules..."

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -q -y iptables iptables-persistent netfilter-persistent

    iptables -I INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --set
    iptables -I INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP

    ip6tables -I INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --set
    ip6tables -I INPUT -p tcp --dport $SSH_PORT -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP

    netfilter-persistent save
    echo "Firewall rules configured and saved."
}

# Main menu function
main_menu() {
    while true; do
        echo "=============================="
        echo "       SSH Configuration      "
        echo "=============================="
        echo "1. Regenerate SSH Host Keys"
        echo "2. Apply SSH Hardening Configuration"
        echo "3. Configure Firewall Rules"
        echo "4. Exit"
        read -rp "Choose an option: " choice

        case $choice in
            1) regenerate_ssh_keys ;;
            2) apply_ssh_hardening ;;
            3) configure_firewall ;;
            4)
                echo "Exiting script. Hasta La Vista!"
                exit 0
                ;;
            *)
                echo "Error: 'Cannot find variable \"common sense\".' Did you accidentally delete it?"
                ;;
        esac
        read -rp "Press Enter to continue..."
    done
}

# Run the menu
main_menu
