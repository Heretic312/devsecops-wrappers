#!/bin/bash
# Author: Victor Bishop (Heretic312)
# Date Created: 5/5/25
# Menu-based Bash script for deploying a Havoc C2 server on AWS with various configurations

# Function to deploy the Havoc C2 server on AWS
deploy_havoc_c2() {
    echo "Deploying Havoc C2 server on AWS..."
    read -p "Enter AWS region (e.g., us-east-1): " aws_region
    read -p "Enter instance type (e.g., t2.micro): " instance_type
    read -p "Enter key pair name: " key_pair
    read -p "Enter security group ID: " security_group

    # Launch EC2 instance
    instance_id=$(aws ec2 run-instances \
        --region "$aws_region" \
        --instance-type "$instance_type" \
        --key-name "$key_pair" \
        --security-group-ids "$security_group" \
        --image-id ami-12345678 \ # Replace with the correct AMI ID for your region
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "Havoc C2 server deployed. Instance ID: $instance_id"
}

# Function to configure iptables rules
configure_iptables() {
    echo "Configuring iptables rules..."
    read -p "Enter port to allow (e.g., 443): " port
    sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --sport "$port" -j ACCEPT
    echo "iptables rules configured for port $port."
}

# Function to set up socat redirector
setup_socat() {
    echo "Setting up socat redirector..."
    read -p "Enter local port (e.g., 443): " local_port
    read -p "Enter target IP: " target_ip
    read -p "Enter target port (e.g., 443): " target_port

    nohup socat TCP4-LISTEN:"$local_port",fork TCP4:"$target_ip":"$target_port" &
    echo "Socat redirector set up from localhost:$local_port to $target_ip:$target_port."
}

# Function to configure HTTPS redirector using Apache/Nginx/Caddy
setup_https_redirector() {
    echo "Choose proxy software:"
    echo "1) Apache"
    echo "2) Nginx"
    echo "3) Caddy"
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1)
            echo "Setting up Apache as HTTPS redirector..."
            sudo apt update && sudo apt install apache2 -y
            sudo a2enmod proxy proxy_http ssl rewrite headers
            echo "
<VirtualHost *:443>
  ServerName example.com # Replace with your domain
  ProxyPreserveHost On
  ProxyPass / https://127.0.0.1:5443/
  ProxyPassReverse / https://127.0.0.1:5443/
  SSLEngine on
  SSLCertificateFile /path/to/cert.pem # Replace with your cert path
  SSLCertificateKeyFile /path/to/key.pem # Replace with your key path
</VirtualHost>" | sudo tee /etc/apache2/sites-available/redirector.conf

            sudo a2ensite redirector.conf && sudo systemctl restart apache2
            ;;
        2)
            echo "Setting up Nginx as HTTPS redirector..."
            sudo apt update && sudo apt install nginx -y
            echo "
server {
  listen 443 ssl;
  server_name example.com; # Replace with your domain

  ssl_certificate /path/to/cert.pem; # Replace with your cert path
  ssl_certificate_key /path/to/key.pem; # Replace with your key path

  location / {
      proxy_pass https://127.0.0.1:5443;
      proxy_set_header Host \$host;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}" | sudo tee /etc/nginx/sites-available/redirector.conf

            sudo ln -s /etc/nginx/sites-available/redirector.conf /etc/nginx/sites-enabled/
            sudo systemctl restart nginx
            ;;
        3)
            echo "Setting up Caddy as HTTPS redirector..."
            curl -fsSL https://getcaddy.com | bash -s personal
            echo "
example.com { # Replace with your domain
  reverse_proxy https://127.0.0.1:5443 {
      header_up Host {host}
      header_up X-Forwarded-For {remote}
      header_up X-Forwarded-Port {server_port}
  }
}" | sudo tee /etc/caddy/Caddyfile

            sudo systemctl restart caddy
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac

    echo "HTTPS redirector configured."
}

# Main menu loop
while true; do
    echo ""
    echo "--- Red Team Infrastructure Setup ---"
    echo "1) Deploy Havoc C2 Server on AWS"
    echo "2) Configure iptables Rules"
    echo "3) Set Up Socat Redirector"
    echo "4) Configure HTTPS Redirector (Apache/Nginx/Caddy)"
    echo "5) Exit"
    read -p "Enter your choice [1-5]: " main_choice

    case $main_choice in
        1) deploy_havoc_c2 ;;
        2) configure_iptables ;;
        3) setup_socat ;;
        4) setup_https_redirector ;;
        5) break ;;
        *) echo "Invalid choice." ;;
    esac
done

echo "Exiting script."
