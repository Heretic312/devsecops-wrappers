#!/bin/bash
# Author: Victor Bishop (Heretic312)
# Date Created: 10/9/2025
# Regenerate SSH host keys
regenerate_ssh_keys() {
    echo "Regenerating SSH host keys..."
    rm /etc/ssh/ssh_host_*
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    echo -e "\nHostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config
    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli
    echo "SSH host keys regenerated successfully."
}

# Apply SSH hardening configuration
apply_ssh_hardening() {
    echo "Applying SSH hardening configuration..."
    echo -e "# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\n
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\n\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr\n\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\n\nHostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nRequiredRSASize 3072\n\nCASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nGSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-\n\nHostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\nPubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\n" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
    service ssh restart
    echo "SSH hardening configuration applied successfully."
}

# Configure iptables rules
configure_firewall() {
    echo "Configuring iptables firewall rules..."
    DEBIAN_FRONTEND=noninteractive apt install -q -y iptables netfilter-persistent iptables-persistent
    iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
    ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
    service netfilter-persistent save
    echo "Firewall rules configured successfully."
}

# Main menu
main_menu() {
    while true; do
        echo "###"
        echo "       SSH Configuration      "
        echo "###"
        echo "1. Regenerate SSH Host Keys"
        echo "2. Apply SSH Hardening Configuration"
        echo "3. Configure Firewall Rules"
        echo "4. Exit"
        read -p "Choose an option: " choice

        case $choice in
            1)
                regenerate_ssh_keys
                ;;
            2)
                apply_ssh_hardening
                ;;
            3)
                configure_firewall
                ;;
            4)
                echo "Exiting script. Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac

        # Pause before showing the menu again
        read -p "Press Enter to continue..."
    done
}

# Run the main menu
main_menu
