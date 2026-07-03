#!/bin/bash
# Author: Victor Bishop (Heretic313)
# Date Created: 8/19/2025
# Variables - customize these based on your setup
LIGHTSAIL_INSTANCE_NAME="sliver-c2-instance"
LIGHTSAIL_REGION="us-east-1"
DOMAIN_NAME="evil.com"
ON_PREMISE_C2_IP="192.168.1.100"
ON_PREMISE_C2_PORT=443
SSH_KEY_NAME="sliver-key" # Replace with your Lightsail SSH key name
SSH_USER="ubuntu" # Default user for Ubuntu Lightsail instances
REVERSE_PORT=2222
REDIRECT_PORT=443

# Step 1: Create a Lightsail instance
echo "[*] Creating Lightsail instance..."
aws lightsail create-instances \
    --instance-names $LIGHTSAIL_INSTANCE_NAME \
    --availability-zone "$LIGHTSAIL_REGION" \
    --blueprint-id "ubuntu_20_04" \
    --bundle-id "nano_2_0" \
    --key-pair-name $SSH_KEY_NAME

# Wait for the instance to start
echo "[*] Waiting for the instance to become available..."
sleep 120

# Get the public IP of the Lightsail instance
LIGHTSAIL_PUBLIC_IP=$(aws lightsail get-instance --instance-name $LIGHTSAIL_INSTANCE_NAME --query 'instance.publicIpAddress' --output text)
echo "[*] Lightsail instance public IP: $LIGHTSAIL_PUBLIC_IP"

# Step 2: Configure DNS to point to the Lightsail instance
echo "[*] Configuring DNS for domain $DOMAIN_NAME..."
aws route53 change-resource-record-sets \
    --hosted-zone-id <your-hosted-zone-id> \
    --change-batch '{
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'"$DOMAIN_NAME"'",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [{"Value": "'"$LIGHTSAIL_PUBLIC_IP"'"}]
            }
        }]
    }'

# Step 3: Install dependencies on the Lightsail instance
echo "[*] Installing dependencies on the Lightsail instance..."
ssh -i ~/.ssh/$SSH_KEY_NAME.pem $SSH_USER@$LIGHTSAIL_PUBLIC_IP <<EOF
sudo apt update && sudo apt install -y socat autossh curl unzip
EOF

# Step 4: Set up reverse SSH tunnel from on-premise C2 server to Lightsail instance
echo "[*] Setting up reverse SSH tunnel..."
ssh -i ~/.ssh/$SSH_KEY_NAME.pem $SSH_USER@$LIGHTSAIL_PUBLIC_IP <<EOF
autossh -M 0 -f -N -R $REVERSE_PORT:$ON_PREMISE_C2_IP:$ON_PREMISE_C2_PORT $SSH_USER@$LIGHTSAIL_PUBLIC_IP
EOF

# Step 5: Configure TCP redirection on the Lightsail instance
echo "[*] Configuring TCP redirection with socat..."
ssh -i ~/.ssh/$SSH_KEY_NAME.pem $SSH_USER@$LIGHTSAIL_PUBLIC_IP <<EOF
sudo socat TCP-LISTEN:$REDIRECT_PORT,fork TCP:127.0.0.1:$REVERSE_PORT &
EOF

# Step 6: Install and configure Sliver C2 server on the on-premise machine
echo "[*] Installing Sliver C2 server on on-premise machine..."
curl https://sliver.sh/install | sudo bash

# Generate SSL certificates (ensure you have certbot or OpenSSL installed)
echo "[*] Generating SSL certificates for domain $DOMAIN_NAME..."
sudo certbot certonly --standalone -d $DOMAIN_NAME

# Configure Sliver with mTLS listener
echo "[*] Configuring Sliver C2 server..."
sliver-server <<EOF
mtls -L $ON_PREMISE_C2_IP -l $ON_PREMISE_C2_PORT --cert /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem --key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem
EOF

echo "[*] Deployment complete! Your Sliver C2 server is now accessible via $DOMAIN_NAME."