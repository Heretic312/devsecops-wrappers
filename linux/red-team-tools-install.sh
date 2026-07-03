#!/bin/bash
# Top Red Team Tools Installer Script
# Author: Heretic312

### How to Use the Script:
#1. Save the script as `red-team-tools-install.sh`.
#2. Make it executable:
#  
#   chmod +x red-team-tools-install.sh
#   
#3. Run the script:
#   
#   ./red-team-tools-install.sh
#   
#4. Follow the prompts in the menu to select and install tools for each category.

#This modular structure allows easy extension by adding more functions for other categories like *Credential Dumping*, *Privilege Escalation*, etc., and updating the main menu accordingly.

# Install reconnaissance tools
install_recon_tools() {
    echo "Installing Reconnaissance Tools..."
    sudo apt update
    sudo apt install -y rustscan
    git clone https://github.com/21y4d/nmapAutomator.git
    git clone https://github.com/Tib3rius/AutoRecon.git
    sudo apt install -y amass
    git clone https://github.com/initstring/cloud_enum.git
    git clone https://github.com/lanmaster53/recon-ng.git
    git clone https://github.com/superhedgy/AttackSurfaceMapper.git
    git clone https://github.com/1N3/dnsdumpster.git
    echo "Reconnaissance Tools Installed."
}

# Install initial access tools
install_initial_access_tools() {
    echo "Installing Initial Access Tools..."
    git clone https://github.com/byt3bl33d3r/SprayingToolkit.git
    git clone https://github.com/nyxgeek/o365recon.git
    git clone https://github.com/L4bF0x/psudohash.git
    git clone https://github.com/ihebski/CredMaster.git
    git clone https://github.com/dafthack/DomainPasswordSpray.git
    git clone https://github.com/BlackDiverX/TheSprayer.git
    git clone https://github.com/blacklanternsecurity/TREVORspray.git
    echo "Initial Access Tools Installed."
}

# Install delivery tools
install_delivery_tools() {
    echo "Installing Delivery Tools..."
    git clone https://github.com/mdsecactivebreach/o365-attack-toolkit.git
    git clone https://github.com/kgretzky/evilginx2.git
    git clone https://github.com/gophish/gophish.git
    git clone https://github.com/fireeye/PwnAuth.git
    git clone https://github.com/drk1wi/Modlishka.git
    echo "Delivery Tools Installed."
}

# Function to install C2 tools
install_c2_tools() {
    echo "Installing Command and Control (C2) Tools..."
    git clone https://github.com/nettitude/PoshC2.git
    git clone https://github.com/BishopFox/sliver.git
    git clone https://github.com/byt3bl33d3r/SILENTTRINITY.git
    git clone https://github.com/EmpireProject/Empire.git
    git clone https://github.com/AzureAD/AzureC2Relay.git
    git clone https://github.com/HavocFramework/Havoc.git
    git clone https://github.com/MythicC2/Mythic.git
    echo "Command and Control (C2) Tools Installed."
}

# Add more functions for other categories here...

# Main menu function
main_menu() {
  while true; do
      echo "Select a category to install tools:"
      echo "1) Reconnaissance"
      echo "2) Initial Access"
      echo "3) Delivery"
      echo "4) Command and Control (C2)"
      # Extend the menu for other categories as needed...
      echo "5) Exit"
      read -p "Enter your choice: " choice

      case $choice in
          1)
              install_recon_tools ;;
          2)
              install_initial_access_tools ;;
          3)
              install_delivery_tools ;;
          4)
              install_c2_tools ;;
          # Add cases for other categories...
          5)
              echo "Exiting..."
              exit 0 ;;
          *)
              echo "Invalid option. Please try again." ;;
      esac
  done
}

# Run main menu function
main_menu




