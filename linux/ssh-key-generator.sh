#!/bin/bash

# Author: Victor Bishop (heretic312)
# Date: 7/25/2025
# Auto SSH Key Generator 
# Make script executable: chmod +x ssh-key-generator

# Define variables
KEY_DIR="$HOME/.ssh"
PRIVATE_KEY="$KEY_DIR/id_rsa"
PUBLIC_KEY="$PRIVATE_KEY.pub"
KEY_BITS=4096  # Key size (e.g., 2048 or 4096 bits)

# Ensure the .ssh directory exists with proper permissions
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

# Prompt the user for passphrase option
read -p "Do you want to set a passphrase for your SSH key? (yes/no): " SET_PASSPHRASE

if [[ "$SET_PASSPHRASE" == "yes" ]]; then
    # Prompt for passphrase
    read -sp "Enter your passphrase: " PASSPHRASE
    echo
    read -sp "Confirm your passphrase: " CONFIRM_PASSPHRASE
    echo

    # Check if passphrases match
    if [[ "$PASSPHRASE" != "$CONFIRM_PASSPHRASE" ]]; then
        echo "Error: Passphrases do not match bro. Exit stage left."
        exit 1
    fi
else
    # No passphrase (empty string)
    PASSPHRASE=""
fi

# Generate SSH key pair with or without a passphrase
ssh-keygen -t rsa -b "$KEY_BITS" -f "$PRIVATE_KEY" -N "$PASSPHRASE" -q

# Output the results
echo "SSH key pair generated:"
echo "Private Key: $PRIVATE_KEY"
echo "Public Key: $PUBLIC_KEY"

# Optional: Display the public key content for easy copying
echo "Public Key Content:"
cat "$PUBLIC_KEY"
