#!/bin/bash
# Author: Victor Bishop
# Date: 5-18-2025

# List of hosts and ports to check
HOSTS=("server1.example.com:443" "server2.example.com:443" "cisco-switch.example.com:443")
WARNING_DAYS=30

for HOST in "${HOSTS[@]}"; do
  EXPIRY_DATE=$(echo | openssl s_client -connect $HOST -servername $HOST 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
  EXPIRY_SECONDS=$(date -d "$EXPIRY_DATE" +%s)
  NOW_SECONDS=$(date +%s)
  DAYS_LEFT=$(( ($EXPIRY_SECONDS - $NOW_SECONDS) / 86400 ))
  if [ "$DAYS_LEFT" -le "$WARNING_DAYS" ]; then
    echo "Certificate for $HOST expires in $DAYS_LEFT days ($EXPIRY_DATE)"
    # Optionally send an email or alert here
  fi
done
