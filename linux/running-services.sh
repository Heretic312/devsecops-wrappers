#!/bin/bash
# Description:  Basic Pretty Systemctl Services Status Script
# Author:  Victor Bishop (Heretic)  |  https://github.com/Heretic312/devsecops-wrappers
# Date:  12/12/2025

# List all systemctl services and color them based on their status
systemctl list-unit-files | awk '
/enabled/ {print "\033[32m" $0 "\033[0m"; next}  # Green for enabled
/disabled/ {print "\033[31m" $0 "\033[0m"; next}  # Red for disabled
/static/ {print "\033[34m" $0 "\033[0m"; next}    # Blue for static
/alias/ {print "\033[35m" $0 "\033[0m"; next}    # Purple for alias
{print $0}  # Default output for other lines
'

# List all systemctl services and color the whole line for enabled services
#systemctl list-unit-files | awk '/enabled/ {print "\033[32m" $0 "\033[0m"; next} {print $0}'


# List all running systemctl services and highlight enabled ones with color
#systemctl list-unit-files | grep --color=auto 'enabled'
