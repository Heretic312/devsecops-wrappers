#!/bin/bash

# Script Name: debian-hardening-pro-menu.sh
# Description: Menu-driven Debian 12 server hardening. Interactive version of
#              debian-hardening-pro.sh: each step can be run on its own, or
#              all steps can be applied in sequence.
# Author: Victor Bishop (Heretic312) | https://github.com/Heretic312/devsecops-wrappers
# Usage: sudo ./debian-hardening-pro-menu.sh
# Notes: Must be run as root. Review each step before applying it to a
#        production host.

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Update and upgrade system packages
update_system() {
    echo "Updating system packages..."
    apt update && apt upgrade -y
}

# Install essential security packages
install_security_packages() {
    echo "Installing essential security packages..."
    apt install -y ufw fail2ban unattended-upgrades
}

# Configure the UFW firewall
configure_firewall() {
    echo "Configuring UFW firewall..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw --force enable
}

# Harden the SSH configuration
harden_ssh() {
    echo "Hardening SSH configuration..."
    sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart ssh
}

# Set up automatic security updates
setup_unattended_upgrades() {
    echo "Setting up automatic security updates..."
    dpkg-reconfigure --priority=low unattended-upgrades
}

# Configure Fail2ban for SSH
configure_fail2ban() {
    echo "Configuring Fail2ban..."
    cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
    systemctl restart fail2ban
}

# Disable unnecessary services
disable_services() {
    echo "Disabling unnecessary services..."
    for svc in avahi-daemon cups rpcbind; do
        systemctl disable "$svc" 2>/dev/null || echo "$svc not found or already disabled."
    done
}

# Set secure permissions on sensitive files
secure_file_permissions() {
    echo "Setting secure permissions on sensitive files..."
    chmod 700 /root
    chmod 700 /home/*
    chmod 600 /etc/shadow
    chmod 644 /etc/passwd
}

# Enable process accounting
enable_process_accounting() {
    echo "Enabling process accounting..."
    apt install -y acct
    systemctl enable acct
    systemctl start acct
}

# Enable the auditd service
enable_auditd() {
    echo "Enabling auditd..."
    apt install -y auditd
    systemctl enable auditd
    systemctl start auditd
}

# Disable USB storage devices
disable_usb_storage() {
    echo "Disabling USB storage..."
    echo "install usb-storage /bin/true" > /etc/modprobe.d/disable-usb-storage.conf
}

# Set a secure umask globally
set_secure_umask() {
    echo "Setting secure umask..."
    grep -q "^umask 027" /etc/profile || echo "umask 027" >> /etc/profile
}

# Disable core dumps
disable_core_dumps() {
    echo "Disabling core dumps..."
    grep -q "hard core 0" /etc/security/limits.conf || echo "* hard core 0" >> /etc/security/limits.conf
}

# Secure shared memory
secure_shared_memory() {
    echo "Securing shared memory..."
    grep -q "/run/shm" /etc/fstab || echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
}

# Disable IPv6 if not needed
disable_ipv6() {
    echo "Disabling IPv6..."
    grep -q "disable_ipv6" /etc/sysctl.conf || cat >> /etc/sysctl.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    sysctl -p
}

# Run every hardening step in sequence
run_all() {
    update_system
    install_security_packages
    configure_firewall
    harden_ssh
    setup_unattended_upgrades
    configure_fail2ban
    disable_services
    secure_file_permissions
    enable_process_accounting
    enable_auditd
    disable_usb_storage
    set_secure_umask
    disable_core_dumps
    secure_shared_memory
    disable_ipv6
    echo "Debian 12 server hardening complete. Please reboot the system."
}

# Main menu
main_menu() {
    while true; do
        clear
        echo "Debian 12 Server Hardening"
        echo "--------------------------"
        echo "1) Update and upgrade system packages"
        echo "2) Install security packages (ufw, fail2ban, unattended-upgrades)"
        echo "3) Configure UFW firewall"
        echo "4) Harden SSH configuration"
        echo "5) Set up automatic security updates"
        echo "6) Configure Fail2ban"
        echo "7) Disable unnecessary services (avahi-daemon, cups, rpcbind)"
        echo "8) Set secure permissions on sensitive files"
        echo "9) Enable process accounting"
        echo "10) Enable auditd"
        echo "11) Disable USB storage"
        echo "12) Set secure umask (027)"
        echo "13) Disable core dumps"
        echo "14) Secure shared memory"
        echo "15) Disable IPv6"
        echo "16) Run all steps"
        echo "17) Exit"
        read -rp "Enter your choice [1-17]: " choice
        case $choice in
            1) update_system ;;
            2) install_security_packages ;;
            3) configure_firewall ;;
            4) harden_ssh ;;
            5) setup_unattended_upgrades ;;
            6) configure_fail2ban ;;
            7) disable_services ;;
            8) secure_file_permissions ;;
            9) enable_process_accounting ;;
            10) enable_auditd ;;
            11) disable_usb_storage ;;
            12) set_secure_umask ;;
            13) disable_core_dumps ;;
            14) secure_shared_memory ;;
            15) disable_ipv6 ;;
            16) run_all ;;
            17) echo "Exiting."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
        read -rp "Press Enter to continue..."
    done
}

main_menu
