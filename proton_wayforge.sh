#!/bin/bash

# Torrent file provided locally
ENDEAVOUROS_TORRENT_PATH="/mnt/data/EndeavourOS_Endeavour_neo-2024.09.22.iso.torrent"
ENDEAVOUROS_ISO_PATH="$HOME/endeavouros.iso"
ETCHER_APPIMAGE_URL="https://github.com/balena-io/etcher/releases/download/v1.5.122/balenaEtcher-1.5.122-x64.AppImage"
ETCHER_APPIMAGE_PATH="$HOME/balenaEtcher.AppImage"

# Function to detect if we are in SteamOS or EndeavourOS Live environment
detect_environment() {
    if grep -q "SteamOS" /etc/os-release; then
        echo "Running in SteamOS."
        IS_STEAMOS=1
    elif grep -q "EndeavourOS" /etc/os-release; then
        echo "Running in EndeavourOS live environment."
        IS_STEAMOS=0
    else
        echo "Unknown environment. Exiting."
        exit 1
    fi
}

# Function to check if qBittorrent is installed
check_torrent_client() {
    if ! command -v qbittorrent >/dev/null 2>&1; then
        echo "qBittorrent not found. Installing qBittorrent..."
        sudo pacman -Sy --noconfirm qbittorrent
    fi

    if command -v qbittorrent >/dev/null 2>&1; then
        echo "qBittorrent installed successfully."
    else
        echo "Failed to install qBittorrent. Exiting."
        exit 1
    fi
}

# Function to launch qBittorrent with the provided torrent file
launch_qbittorrent() {
    echo "Launching qBittorrent to download the EndeavourOS ISO..."
    qbittorrent "$ENDEAVOUROS_TORRENT_PATH" &

    if [[ $? -eq 0 ]]; then
        echo "qBittorrent launched successfully. Please use the GUI to monitor the download."
    else
        echo "Failed to launch qBittorrent."
        exit 1
    fi
}

# Function to download Balena Etcher AppImage
download_etcher_appimage() {
    echo "Downloading Balena Etcher AppImage..."
    wget -O "$ETCHER_APPIMAGE_PATH" "$ETCHER_APPIMAGE_URL"

    if [[ $? -eq 0 ]]; then
        echo "Balena Etcher AppImage downloaded successfully to $ETCHER_APPIMAGE_PATH."
        chmod +x "$ETCHER_APPIMAGE_PATH"  # Make it executable
    else
        echo "Failed to download Balena Etcher AppImage. Please check your connection."
        exit 1
    fi
}

# Function to select USB or microSD
select_storage_device() {
    echo "Please select the storage device for flashing the EndeavourOS ISO:"
    echo "1) USB Drive"
    echo "2) microSD Card"
    read -p "Enter your choice (1 or 2): " choice

    case $choice in
        1)
            DEVICE_PATH=$(lsblk -o NAME,SIZE,TYPE | grep "disk" | grep -i sd[b-z])
            echo "Detected USB drive: $DEVICE_PATH"
            ;;
        2)
            DEVICE_PATH=$(lsblk -o NAME,SIZE,TYPE | grep "disk" | grep -i mmcblk)
            echo "Detected microSD card: $DEVICE_PATH"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}

# Function to launch Balena Etcher
launch_etcher() {
    echo "Launching Balena Etcher..."
    "$ETCHER_APPIMAGE_PATH" &

    if [[ $? -eq 0 ]]; then
        echo "Balena Etcher launched successfully. Please use the GUI to flash the EndeavourOS ISO to the $DEVICE_PATH."
    else
        echo "Failed to launch Balena Etcher."
        exit 1
    fi
}

# Function to prompt the user to reboot manually into the USB or microSD
prompt_reboot() {
    echo -e "\n###########################################"
    echo "EndeavourOS live USB or microSD has been prepared."
    echo "Please reboot your Steam Deck and boot from the selected device."
    echo "Once you are booted into the EndeavourOS live environment, run this script again."
    echo "###########################################"
}

# Function to install KDE, GParted, and other necessary tools in the live environment
install_tools_in_live_env() {
    echo "Installing KDE, GParted, and other necessary tools..."
    sudo pacman -Sy --noconfirm plasma gparted

    if [[ $? -eq 0 ]]; then
        echo "Tools installed successfully."
    else
        echo "Failed to install tools."
        exit 1
    fi
}

# Function to resize /var partitions to 5GB each
resize_var_partition() {
    echo "Detecting /var partitions for resizing..."

    VAR_PARTITIONS=$(lsblk -o NAME,MOUNTPOINT | grep "/var" | awk '{print $1}')

    if [ -z "$VAR_PARTITIONS" ]; then
        echo "No /var partitions detected. Exiting."
        exit 1
    fi

    for part in $VAR_PARTITIONS; do
        echo "Resizing /dev/$part to 5GB..."
        sudo parted /dev/"$(echo "$part" | sed 's/[0-9]//g')" resizepart "$(echo "$part" | sed 's/[^0-9]//g')" 5GB
        sudo resize2fs /dev/$part 5G
        echo "Partition /dev/$part resized to 5GB."
    done

    echo "All /var partitions resized successfully."
}

# Main function for handling both environments
main() {
    # Detect if we are in SteamOS or EndeavourOS live environment
    detect_environment

    if [[ $IS_STEAMOS -eq 1 ]]; then
        # Check and install torrent client if necessary
        check_torrent_client

        # Launch qBittorrent to download the ISO
        launch_qbittorrent

        # Download and launch Balena Etcher
        download_etcher_appimage

        # Select USB or microSD for flashing
        select_storage_device
        launch_etcher
        prompt_reboot
    else
        # If we are in EndeavourOS live environment, install tools and resize partitions
        install_tools_in_live_env
        resize_var_partition
    fi
}

# Run the main function
main
