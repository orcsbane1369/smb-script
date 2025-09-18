Automated Samba (SMB) Mount Script
This is a simple, yet robust, shell script designed to simplify the process of permanently mounting a Samba (SMB) share on Ubuntu 20.04 and newer Linux distributions.

The script automates several manual and sometimes tricky steps:

Installs necessary dependencies (smbclient and cifs-utils).

Creates a secure credentials file for your username and password.

Sets up a permanent mount point and adds an entry to your /etc/fstab file.

This ensures your share is automatically mounted every time you boot your machine.

How to Use
Download the script:
You can either clone the repository or download the script directly using wget or curl.

wget [https://raw.githubusercontent.com/YourUsername/YourRepoName/main/smb_mount_setup.sh](https://raw.githubusercontent.com/YourUsername/YourRepoName/main/smb_mount_setup.sh)

Make the script executable:
Before you can run it, you must give the script execute permissions.

chmod +x smb_mount_setup.sh

Run the script with sudo:
The script requires root privileges to install packages and edit system files.

sudo ./smb_mount_setup.sh

Follow the prompts:
The script will guide you through the process, asking for the following information:

SMB Share Path: The full path to the share, e.g., //192.168.2.46/video.

Username & Password: Your credentials for the share. The password will be hidden as you type.

SMB Protocol Version: The script will ask for the SMB protocol version (e.g., 3.0, 2.1, 1.0). If you are unsure, 3.0 is a good place to start, as it is the most common and secure version.

Security Option (sec): The script will prompt you for an optional sec parameter. This is a common solution for troubleshooting mount errors. If a default mount fails, you can try values like ntlmssp or ntlmv2. You can safely leave this blank on the first attempt.

What the Script Does
Creates a secure credentials file: It creates a file named after the server and share (server_share.cred) in /etc/samba/creds/ and sets its permissions to 600, ensuring only the root user can read it.

Creates a mount point: A directory with the same name as the share is created in /mnt/ (e.g., /mnt/video).

Updates /etc/fstab: The script adds a line to /etc/fstab so that the share is mounted automatically on boot.

After the script finishes, it will provide you with the exact command to mount the share immediately without a reboot.

Troubleshooting
read: not a valid identifier error: If you see this error, it is likely that the file was edited on a Windows machine. To fix it, install dos2unix and run it on the script file:

sudo apt-get install dos2unix
dos2unix smb_mount_setup.sh

Mount Errors (mount -a): If the automatic mount on boot fails, try to run sudo dmesg | tail after attempting the mount. The kernel logs often provide a more detailed reason for the failure, which can help pinpoint an incorrect option (like vers or sec) in your /etc/fstab file.