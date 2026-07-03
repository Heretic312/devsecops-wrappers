#!/bin/bash
# Author: Victor Bishop (Heretic312)
# Date Created: 9/23/2025
# Display Menu
show_menu() {
    echo "Red Team Infrastructure Deployment Script"
    echo "-----------------------------------------"
    echo "1. Deploy Phishing/Payload Server (GoPhish)"
    echo "2. Deploy C2 Team Server (e.g., Sliver)"
    echo "3. Deploy HTTPS Redirector (Caddy)"
    echo "4. Deploy DNS Redirector (Socat/Iptables)"
    echo "5. Configure Postfix Redirector for Phishing"
    echo "6. Set Up Outlook Instance for Mail Relay"
    echo "7. Automate Infrastructure with Terraform/Ansible"
    echo "8. Exit"
}

# Deploy GoPhish server
deploy_phishing_server() {
    echo "Deploying Phishing/Payload Server..."
    sudo apt-get update && sudo apt-get install -y golang
    wget https://github.com/gophish/gophish/releases/latest/download/gophish-linux-64bit.zip
    unzip gophish-linux-64bit.zip -d /opt/gophish
    cat <<EOF > /etc/systemd/system/gophish.service
[Unit]
Description=GoPhish Phishing Server
After=network.target

[Service]
ExecStart=/opt/gophish/gophish
WorkingDirectory=/opt/gophish
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable gophish && systemctl start gophish
    echo "GoPhish server deployed and started."
}

# Deploy C2 server (e.g., Sliver)
deploy_c2_server() {
    echo "Deploying C2 Team Server..."
    curl -LO https://github.com/BishopFox/sliver/releases/latest/download/sliver-server_linux
    chmod +x sliver-server_linux && mv sliver-server_linux /usr/local/bin/sliver-server
    sliver-server --init &> /dev/null &
    echo "C2 Team Server deployed using Sliver."
}

# Deploy HTTPS Redirector with Caddy
deploy_https_redirector() {
    echo "Deploying HTTPS Redirector with Caddy..."
    
    # Install Caddy
    sudo apt-get update && sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update && sudo apt install -y caddy

    # Configure Caddyfile for HTTPS redirector
    read -p "Enter domain name for redirector: " domain_name
    read -p "Enter backend server IP and port (e.g., http://127.0.0.1:5443): " backend_url

    cat <<EOF > /etc/caddy/Caddyfile
$domain_name {
    reverse_proxy /supersecretlocation/* $backend_url {
        header_up Host {host}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
        header_down Access-Control-Allow-Origin *
        header_down Access-Control-Allow-Methods GET, POST, OPTIONS
        header_down Access-Control-Allow-Headers Content-Type, Authorization
        @block_user_agent not user_agent Supersecretuseragent
        respond @block_user_agent 404
    }

    root * /var/www/html
    file_server browse
}
EOF

    # Restart Caddy to apply configuration changes
    systemctl restart caddy
    
    echo "HTTPS Redirector configured and running with Caddy."
}

# Deploy DNS Redirector with Socat/Iptables
deploy_dns_redirector() {
    echo "Deploying DNS Redirector..."
    sudo apt-get update && sudo apt-get install -y socat iptables
    read -p "Enter C2 server IP: " c2_ip
    
    nohup socat UDP4-LISTEN:53,fork UDP4:$c2_ip:53 &
    
    iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination $c2_ip:53
    iptables-save > /etc/iptables/rules.v4
    
    echo "DNS Redirector deployed."
}

# Configure Postfix Redirector for phishing emails
configure_postfix_redirector() {
    echo "Configuring Postfix Redirector..."
    
cat <<EOF > /etc/postfix/header_checks.cf
/^Received:/ IGNORE
/^X-Mailer:/ IGNORE
/^Message-ID:/ IGNORE
/^User-Agent:/ IGNORE
/^X-Originating-IP:/ IGNORE
EOF

postconf -e 'header_checks = regexp:/etc/postfix/header_checks.cf'
systemctl restart postfix

echo "Postfix Redirector configured."
}

# Set up Outlook instance for mail relay (requires Azure setup)
setup_outlook_instance() {
cat <<'EOF'
Please follow these steps manually:
1. Purchase an Office365 license.
2. Set up an Azure virtual machine with SMTP authentication enabled.
3. Configure your Outlook instance as an SMTP relay.
4. Use Gophish's Sending Profiles to integrate the Postfix redirector with Outlook.
EOF

}

# Automate infrastructure with Terraform/Ansible/Vagrant
automate_infrastructure() {
cat <<'EOF'
Automating infrastructure requires additional setup:
1. Use Terraform to provision cloud resources like AWS or Azure instances.
2. Use Vagrant for local VM provisioning.
3. Use Ansible playbooks for software installation and configuration.
Refer to the article's recommendations for modular automation scripts.
EOF

}

# Main loop for menu selection
while true; do
  show_menu
  
  read -p "Enter your choice [1-8]: " choice
  
  case $choice in 
      1) deploy_phishing_server ;;
      2) deploy_c2_server ;;
      3) deploy_https_redirector ;;
      4) deploy_dns_redirector ;;
      5) configure_postfix_redirector ;;
      6) setup_outlook_instance ;;
      7) automate_infrastructure ;;
      8) echo "Exiting script."; exit ;;
      *) echo "Invalid choice, please try again." ;;
  esac

done
