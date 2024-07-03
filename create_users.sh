#!/bin/bash

LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" | tee -a $LOGFILE
    exit 1
fi

# Ensure the password file is secure
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <name-of-text-file>" | tee -a $LOGFILE
    exit 1
fi

# Check if the input file exists and is readable
if [ ! -r "$1" ]; then
    echo "File $1 does not exist or is not readable" | tee -a $LOGFILE
    exit 1
fi

# Read the file line by line
while IFS=';' read -r username groups; do
    # Remove leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create personal group for the user if it doesn't exist
    if ! getent group "$username" &>/dev/null; then
        groupadd "$username"
        echo "Personal group $username created" | tee -a $LOGFILE
    fi

    # Create the user if it doesn't exist
    if id "$username" &>/dev/null; then
        echo "User $username already exists" | tee -a $LOGFILE
    else
        useradd -m -g "$username" -G "$username" "$username" 2>>$LOGFILE
        echo "User $username created" | tee -a $LOGFILE
    fi

    # Generate a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> $PASSWORD_FILE
    echo "Password for $username set" | tee -a $LOGFILE

    # Assign user to additional groups
    if [ -n "$groups" ]; then
        IFS=',' read -ra group_array <<< "$groups"
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)
            # Create group if it doesn't exist
            if ! getent group "$group" &>/dev/null; then
                groupadd "$group"
                echo "Group $group created" | tee -a $LOGFILE
            fi
            usermod -aG "$group" "$username"
            echo "User $username added to group $group" | tee -a $LOGFILE
        done
    fi

done < "$1"
