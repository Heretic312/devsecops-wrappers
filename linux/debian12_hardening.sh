#!/bin/bash
# Debian 12 Server Hardening Script with User Menu (Improved)
# Several options to harden a vanilla Debian 12 Server
# Author:  Victor Bishop (Heretic)  |  https://github.com/Heretic312/devsecops-wrappers.git
# Date:  2/1/2025

# Function to update and upgrade system packages
update_system() {
    echo "Updating system packages from Debian repository..."
    apt update && apt upgrade -y
}

# Function to install essential security packages
install_security_packages() {
    echo "Installing Essential Security Packages..."
    apt install -y ufw fail2ban unattended-upgrades rkhunter lynis
}

# Function to configure UFW firewall
configure_firewall() {
    echo "Setting Up Firewall..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 2222/tcp
    ufw enable
}

# Function to harden SSH configuration
harden_ssh() {
    echo "Hardening SSH Configuration..."
    sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh
}

# Function to set up unattended upgrades
setup_unattended_upgrades() {
    echo "Setting Up Unattended-Upgrades..."
    dpkg-reconfigure --priority=low unattended-upgrades
}

# Function to configure Fail2Ban
configure_fail2ban() {
    echo "Configuring Fail2Ban..."
    SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    cat << EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
backend = systemd
EOF
    systemctl restart fail2ban
}

# Function to disable unnecessary services
disable_services() {
    echo "Disabling Unnecessary Services..."
    for svc in avahi-daemon cups rpcbind; do
        systemctl disable "$svc" 2>/dev/null || echo "$svc not found or already disabled"
    done
}

# Function to secure file permissions
secure_file_permissions() {
    echo "Securing File Permissions..."
    chmod 700 /root
    find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;
    chmod 600 /etc/shadow
    chmod 644 /etc/passwd
}

# Function to enable process accounting
enable_process_accounting() {
    echo "Enabling Process Accounting..."
    apt install -y acct
    systemctl enable acct
    systemctl start acct
}

# Function to enable auditd service
enable_auditd() {
    echo "Enabling AuditD..."
    apt install -y auditd
    systemctl enable auditd
    systemctl start auditd
}

# Function to disable USB storage devices
disable_usb_storage() {
    echo "Disabling USB Storage..."
    echo "install usb-storage /bin/true" > /etc/modprobe.d/disable-usb-storage.conf
}

# Function to set secure umask value globally
set_secure_umask() {
    echo "Setting Secure Umask..."
    grep -q "umask 027" /etc/profile || echo "umask 027" >> /etc/profile
}

# Function to secure shared memory in fstab file
secure_shared_memory() {
    echo "Securing Shared Memory..."
    grep -q "/run/shm" /etc/fstab || echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab
}

# Function to disable IPv6 if not needed
disable_ipv6() {
    echo "Disabling IPv6..."
    grep -q "disable_ipv6" /etc/sysctl.conf || cat << EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    sysctl -p 
}

# Main menu function for user interaction.
main_menu() {
    while true; do
        clear
        echo "Debian 12 Server Hardening Script"
        echo "---------------------------------"
        echo "Please select an option:"
        echo "1) Update and Upgrade System Packages"
        echo "2) Install Essential Security Packages"
        echo "3) Configure UFW Firewall"
        echo "4) Harden SSH Configuration"
        echo "5) Set Up Unattended Upgrades"
        echo "6) Configure Fail2Ban"
        echo "7) Disable Unnecessary Services"
        echo "8) Secure File Permissions"
        echo "9) Enable Process Accounting"
        echo "10) Enable AuditD Service"
        echo "11) Disable USB Storage"
        echo "12) Set Secure Umask"
        echo "13) Secure Shared Memory"
        echo "14) Disable IPv6"
        echo "15) Exit"

        read -p "Enter your choice [1-15]: " choice

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
            13) secure_shared_memory ;;
            14) disable_ipv6 ;;
            15)
                echo "Exiting script. Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Call the main menu function.
main_menu
