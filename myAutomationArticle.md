# Automating User Creation and Management with a Bash Script
## Introduction
Hello, my name is Sunday Goodnews, a budding SysOps engineer from Nigeria with HNG Internship, and I'm excited to be part of the HNG Internship program. The journey into tech has been both challenging and rewarding, and I believe that sharing knowledge is a crucial part of growth in this field. Today, I’m going to walk you through a script I created to automate user creation and management on a Linux system. This script is particularly useful for system administrators who need to manage multiple users efficiently.

## The Problem
Managing users on a Linux system can be a tedious task, especially when you have to create multiple users, assign them to groups, set up home directories, and generate passwords. Doing this manually is not only time-consuming but also prone to errors. To solve this, I developed a bash script called create_users.sh that automates these tasks.

## The Script
Here's a step-by-step explanation of the script:

Initial Setup
We start by defining some variables and checking if the script is run as root. This is crucial because creating users and modifying system files require root privileges.


#!/bin/bash

LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

## Ensure script is run as root
if [ "$(id -u)" -ne 0; then
    echo "This script must be run as root" | tee -a $LOGFILE
    exit 1
fi

## Ensure the password file is secure
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE
Reading the Input File
The script reads a text file containing usernames and group names. Each line in the file is formatted as user;groups. We check if the input file is provided and readable.

bash
## Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <name-of-text-file>" | tee -a $LOGFILE
    exit 1
fi

## Check if the input file exists and is readable
if [ ! -r "$1" ]; then
    echo "File $1 does not exist or is not readable" | tee -a $LOGFILE
    exit 1
fi
Processing Each Line
We process each line in the input file, creating users and assigning them to groups.

bash
## Read the file line by line
while IFS=';' read -r username groups; do
    # Remove leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create the user if it doesn't exist
    if id "$username" &>/dev/null; then
        echo "User $username already exists" | tee -a $LOGFILE
    else
        useradd -m "$username" -G "$username" 2>>$LOGFILE
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
## Error Handling
The script handles errors gracefully, such as checking for existing users and groups. This ensures that no redundant operations are performed, and appropriate messages are logged.

## Security Considerations
We ensure that the password file is securely stored and only accessible by the root user. This is crucial to protect sensitive information.

bash
# Ensure the password file is secure
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE
Testing the Script
To test the script, create a text file users.txt with the following content:

plaintext
light;sudo,dev,www-data
idimma;sudo
mayowa;dev,www-data
Run the script with the text file as an argument:

bash
sudo bash create_users.sh users.txt
This will create the users, assign them to the specified groups, generate passwords, and log all actions.

# Conclusion
This script simplifies the process of user management on a Linux system. By automating user creation and group assignments, it saves time and reduces the risk of errors. I encourage you to try this script and see how it can streamline your SysOps tasks.

If you’re interested in learning more about the HNG Internship program and how it can help you grow your skills, check out HNG Internship and HNG Hire.

Links to HNG
HNG Internship  https://hng.tech/internship,
HNG Hire https://hng.tech/hire,
