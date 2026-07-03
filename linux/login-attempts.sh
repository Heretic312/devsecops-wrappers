#!/bin/bash

# Extract login attempts from auth.log
grep "sshd.*authentication failure" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -nr
