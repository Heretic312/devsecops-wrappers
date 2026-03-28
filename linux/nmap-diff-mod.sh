#!/bin/bash

#Features
	#1.	Custom Port List: Includes additional ports like Redis (6379, 6380) and others.
	#2.	Banner Grabbing: Uses Nmap’s `banner.nse` script to capture service banners.
	#3.	Historical Tracking: Saves scan results to a log file for comparison.
	#4.	Email Notifications: Sends alerts when differences are detected between scans.

# Author -- heretic312

# Configuration
TARGET="192.168.1.0/24"  # Replace with your target network
PORT_LIST="22,80,443,6379,6380"  # Custom port list
LOG_DIR="./nmap_logs"
CURRENT_LOG="$LOG_DIR/current_scan.log"
PREVIOUS_LOG="$LOG_DIR/previous_scan.log"
DIFF_LOG="$LOG_DIR/diff.log"
EMAIL_RECIPIENT="admin@example.com"
SMTP_SERVER="smtp.example.com"
SMTP_PORT=587
SMTP_USER="your_email@example.com"
SMTP_PASS="your_password"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Step 1: Perform the Nmap scan with custom ports and banner grabbing
echo "Starting Nmap scan on $TARGET..."
nmap -p $PORT_LIST --script=banner -oN "$CURRENT_LOG" "$TARGET"

# Step 2: Compare with the previous scan if it exists
if [ -f "$PREVIOUS_LOG" ]; then
    echo "Comparing current scan with the previous scan..."
    diff "$PREVIOUS_LOG" "$CURRENT_LOG" > "$DIFF_LOG"

    if [ -s "$DIFF_LOG" ]; then
        echo "Differences detected! Sending email alert..."
        
        # Prepare email body
        EMAIL_SUBJECT="Nmap Scan Differences Detected"
        EMAIL_BODY=$(cat <<EOF
Subject: $EMAIL_SUBJECT

Differences detected in Nmap scans:
$(cat "$DIFF_LOG")

Please review the changes.
EOF
        )

        # Send email using sendmail
        echo -e "$EMAIL_BODY" | sendmail -S "$SMTP_SERVER:$SMTP_PORT" \
            -au"$SMTP_USER" -ap"$SMTP_PASS" "$EMAIL_RECIPIENT"
    else
        echo "No differences detected."
    fi
else
    echo "No previous scan found. Saving current scan as baseline."
fi

# Step 3: Rotate logs for historical tracking
mv "$CURRENT_LOG" "$PREVIOUS_LOG"

echo "Scan completed. Logs saved in $LOG_DIR."
