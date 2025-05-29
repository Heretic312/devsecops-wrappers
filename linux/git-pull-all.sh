#!/bin/bash
# Description:  Git Pull all local directories and subdirectories
# Date:  2/1/2025

#  Git Pull All Local Directories/Subdirectories
sudo find . -mindepth 1 -maxdepth 1 -type d -print -exec git -C {} pull \;
