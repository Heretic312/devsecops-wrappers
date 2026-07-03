#!/bin/bash

# Function to install reconnaissance tools
install_recon_tools() {
    zenity --info --text="Installing Reconnaissance Tools..."
    sudo apt update
    sudo apt install -y rustscan
    git clone https://github.com/21y4d/nmapAutomator.git
    git clone https://github.com/Tib3rius/AutoRecon.git
    sudo apt install -y amass
    git clone https://github.com/initstring/cloud_enum.git
    git clone https://github.com/lanmaster53/recon-ng.git
    git clone https://github.com/superhedgy/AttackSurfaceMapper.git
    git clone https://github.com/1N3/dnsdumpster.git
    zenity --info --text="Reconnaissance Tools Installed Successfully."
}

# Function to display the main menu using Zenity
main_menu() {
    while true; do
        CHOICE=$(zenity --list --title="Red Teaming Tools Installer" \
                        --column="Option" --column="Description" \
                        "1" "Install Reconnaissance Tools" \
                        "2" "Install Initial Access Tools" \
                        "3" "Install Delivery Tools" \
                        "4" "Exit")

        case $CHOICE in
            1)
                install_recon_tools ;;
            2)
                zenity --info --text="Initial Access Tools installation not implemented yet." ;;
            3)
                zenity --info --text="Delivery Tools installation not implemented yet." ;;
            4)
                zenity --info --text="Exiting..." 
                exit 0 ;;
            *)
                zenity --error --text="Invalid option. Please try again." ;;
        esac
    done
}

# Run the main menu function
main_menu
