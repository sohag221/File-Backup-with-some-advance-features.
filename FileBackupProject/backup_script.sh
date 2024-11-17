#!/bin/bash

# File Backup with Encryption and Decryption (GUI Enabled)

# Define directories for backup, encrypted, and decrypted files
BACKUP_DIR="./backup"
ENCRYPTED_DIR="$BACKUP_DIR/encrypted"
DECRYPTED_DIR="$BACKUP_DIR/decrypted"

# Create directories if they don't exist
mkdir -p "$ENCRYPTED_DIR" "$DECRYPTED_DIR"

# Prompt for password with Zenity
prompt_password() {
    PASSWORD=$(zenity --password --title="Enter Password")
    if [[ -z "$PASSWORD" ]]; then
        zenity --error --text="Password cannot be empty!"
        return 1
    fi
    return 0
}

# Encrypt and back up a file
backup_file() {
    if ! prompt_password; then
        return
    fi
    
    local file_path="$1"
    local filename=$(basename "$file_path")
    local encrypted_file="$ENCRYPTED_DIR/${filename}.enc"
    
    openssl enc -aes-256-cbc -salt -in "$file_path" -out "$encrypted_file" -pass pass:"$PASSWORD"
    if [[ $? -eq 0 ]]; then
        zenity --info --text="Backup of $file_path completed successfully."
    else
        zenity --error --text="Failed to back up $file_path."
    fi
}

# Decrypt and restore a file
restore_file() {
    if ! prompt_password; then
        return
    fi

    local encrypted_file="$1"
    local filename=$(basename "$encrypted_file" .enc)
    local decrypted_file="$DECRYPTED_DIR/$filename"
    
    openssl enc -d -aes-256-cbc -in "$encrypted_file" -out "$decrypted_file" -pass pass:"$PASSWORD"
    if [[ $? -eq 0 ]]; then
        zenity --info --text="Restored $decrypted_file successfully."
    else
        zenity --error --text="Failed to restore $encrypted_file."
    fi
}

# Backup file selection using Zenity
select_file_for_backup() {
    file_path=$(zenity --file-selection --title="Select a file to backup")
    if [[ -n "$file_path" ]]; then
        if [[ -f "$file_path" ]]; then
            backup_file "$file_path"
        else
            zenity --error --text="Selected file does not exist!"
        fi
    else
        zenity --info --text="No file selected."
    fi
}

# Restore file selection using Zenity
select_file_for_restore() {
    encrypted_file=$(zenity --file-selection --title="Select an encrypted file to restore" --file-filter="*.enc")
    if [[ -n "$encrypted_file" ]]; then
        if [[ -f "$encrypted_file" ]]; then
            restore_file "$encrypted_file"
        else
            zenity --error --text="Selected file does not exist!"
        fi
    else
        zenity --info --text="No file selected."
    fi
}

# Main Menu
show_menu() {
    choice=$(zenity --list \
        --title="File Backup with Encryption" \
        --text="Choose an option:" \
        --radiolist \
        --column="Select" --column="Option" \
        TRUE "Backup a file" \
        FALSE "Restore a file" \
        FALSE "Exit")

    case $choice in
        "Backup a file")
            select_file_for_backup
            ;;
        "Restore a file")
            select_file_for_restore
            ;;
        "Exit")
            running=false
            ;;
        *)
            zenity --error --text="Invalid option selected!"
            ;;
    esac
}

# Run the menu loop
running=true
while $running; do
    show_menu
done

