#!/bin/bash

# This script automates the installation of cifs-utils and the setup
# of a permanent SMB share mount on Ubuntu 20.04 and newer.
# It creates a secure credential file and adds an entry to /etc/fstab.
#
# If you are getting a 'read: not a valid identifier' error, it is likely
# due to Windows line endings. To fix this, run 'dos2unix' on the script:
# sudo apt-get update && sudo apt-get install -y dos2unix
# dos2unix smb_mount_setup.sh

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

# --- Step 1: Install necessary packages ---
echo "Checking for required packages (smbclient and cifs-utils)..."
if ! command -v smbclient &> /dev/null || ! command -v mount.cifs &> /dev/null; then
    echo "Packages not found. Installing now."
    apt-get update
    apt-get install -y smbclient cifs-utils
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install packages. Exiting."
        exit 1
    fi
    echo "Packages installed successfully."
else
    echo "Required packages are already installed."
fi

# --- Step 2: Get user input ---
echo ""
read -p "Enter the full SMB share path (e.g., //server/share): " SMB_SHARE
read -p "Enter the username for the share: " SMB_USER

# Use a secure read for the password
read -s -p "Enter the password for the share: " SMB_PASS
echo "" # Add a newline after the password prompt

read -p "Enter the SMB protocol version (e.g., 3.0, 2.1, 1.0). Press Enter to use 3.0: " SMB_VERSION
# Set a default value if the user input is empty
if [ -z "$SMB_VERSION" ]; then
    SMB_VERSION="3.0"
fi

read -p "Enter the 'sec' option (e.g., ntlm, ntlmssp, ntlmv2). Press Enter to skip: " SEC_OPT
if [ ! -z "$SEC_OPT" ]; then
    SEC_OPT="sec=$SEC_OPT,"
else
    SEC_OPT=""
fi

# --- Step 3: Create a secure credentials file ---
# Create a secure directory if it doesn't exist
CRED_DIR="/etc/samba/creds"
mkdir -p "$CRED_DIR"

# Get a user-friendly filename from the server and share name
SERVER_NAME=$(echo "$SMB_SHARE" | cut -d '/' -f 3)
SHARE_BASE=$(basename "$SMB_SHARE")
CRED_FILENAME="${SERVER_NAME}_${SHARE_BASE}"
CRED_FILE="$CRED_DIR/$CRED_FILENAME.cred"

echo "Creating credentials file: $CRED_FILE"
echo "username=$SMB_USER" > "$CRED_FILE"
echo "password=$SMB_PASS" >> "$CRED_FILE"
chmod 600 "$CRED_FILE"

# --- Step 4: Create mount point and fstab entry ---
# Get a user-friendly mount point name from the last part of the share path
MOUNT_POINT="/mnt/$(basename "$SMB_SHARE")"

# Check if the mount point directory exists, create if not
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point: $MOUNT_POINT"
    mkdir -p "$MOUNT_POINT"
fi

# Check if the fstab entry already exists
if grep -q "$SMB_SHARE" /etc/fstab; then
    echo "Warning: An entry for this share already exists in /etc/fstab."
    echo "No new entry will be added."
else
    # Get the current user's UID and GID for correct permissions
    CURRENT_USER=$(whoami)
    CURRENT_UID=$(id -u "$SUDO_USER")
    CURRENT_GID=$(id -g "$SUDO_USER")

    # The fstab line, with the SMB version, credentials, and security option
    FSTAB_LINE="$SMB_SHARE $MOUNT_POINT cifs credentials=$CRED_FILE,vers=$SMB_VERSION,${SEC_OPT}uid=$CURRENT_UID,gid=$CURRENT_GID,_netdev 0 0"

    echo "Adding the following line to /etc/fstab:"
    echo "$FSTAB_LINE"
    echo "$FSTAB_LINE" >> /etc/fstab

    echo "fstab updated successfully."
fi

# --- Step 5: Final instructions ---
echo ""
echo "Setup complete!"
echo "The credentials file has been saved to '$CRED_FILE' with secure permissions."
echo "An entry has been added to '/etc/fstab' to mount the share at '$MOUNT_POINT'."
echo ""
echo "To mount the share now, run the following command:"
echo "  sudo mount $MOUNT_POINT"
echo ""
echo "The share will be automatically mounted on boot, provided the network is available."
echo "If you need to unmount it, use:"
echo "  sudo umount $MOUNT_POINT"

exit 0
