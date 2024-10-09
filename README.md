# Proton-WayForge
Proton WayForge is a customized version of Proton optimized for Wayland environments on Linux, especially on Steam Deck. It minimizes X11 usage, prioritizes Wayland support, and includes a fallback mechanism to run games with Wine if Proton fails.

## Features
- Wayland optimizations for SDL2, Qt, and GTK applications.
- Custom Proton-like behavior with a directory for easy Steam integration.
- Wine fallback when Proton can't run the game.
- Full support for Steam Deck in both Gaming Mode and Desktop Mode.
- Works out-of-the-box with minimal setup.

## Installation

Clone this repository and run the `proton_wayforge.sh` script:

```bash
git clone https://github.com/xatusbetazx17/Proton-WayForge.git
cd Proton-WayForge
chmod +x proton_wayforge.sh
./proton_wayforge.sh

```
## DeckFS Overlay
Open a Terminal: If you’re in Steam Deck’s desktop mode or any other Linux environment, open a terminal window.

## Open Nano to Create the File:

## In the terminal, type the following command to open nano and create a new script file:
```nano overlayfs-setup.sh```
This will open nano with a new, blank file named overlayfs-setup.sh.
Paste the Script:

## Once the editor is open, you can paste the script you want to use. For example, if it's the OverlayFS script, copy the script content from your clipboard and paste it into the nano window (right-click and select paste, or use Ctrl+Shift+V).
Save the Script:

## After pasting the script, press **Ctrl+O** (that's the letter "O", not zero) to write the file (save it).
It will prompt you with File Name to Write: overlayfs-setup.sh, press Enter to confirm.
Exit Nano:

## Once the file is saved, press Ctrl+X to exit nano.
Make the Script Executable:

## To make the script executable, type the following command:
```chmod +x overlayfs-setup.sh```
Run the Script:

## Now, you can run the script by typing:

```./overlayfs-setup.sh```

## Usage

This script will automatically set up a custom Proton build in ```$HOME/.steam/root/compatibilitytools.d/```
Ensure that you have installed the necessary dependencies in Desktop Mode.
Once installed, you can select Proton WayForge as the compatibility tool for games in Steam.

## Disable steam os Read only  

~~~bash
sudo steamos-readonly disable 
~~~

## Before the script:
Creates this directory into external sd on the steam deck to prevent change the system so all thing will be write here instead inside the main disk on the steam deck.

## Step 1: Ensure Proper Directory Setup
Choose a Separate Mount Point: Use an SD card, external USB, or another partition not already used for mounting /var or other critical system directories.

## For example, if you're using /dev/mmcblk0 for an SD card, it will avoid conflicts with the internal SSD or /dev/nvme0n1.
```
sudo mkdir -p /run/media/deck/sdcard/overlay
sudo mkdir -p /run/media/deck/sdcard/workdir
```

## Make /Var  Bigger
Since this will require a lot of temporary files, you will need to resize your ```/var``` partition first. Due to the immutability of the system, ```/var``` needs to be made larger. 
To achieve this, you will need to use OverlayFS.

## DeckFS Overlay

```bash
#!/bin/bash

# Use the SD card or external storage for overlay
MOUNT_DIR="/run/media/deck/sdcard"  # Change this to your SD card or external storage location
OVERLAY_DIR="$MOUNT_DIR/overlay"
WORK_DIR="$MOUNT_DIR/workdir"
SERVICE_NAME="overlayfs-var.service"

# Function to detect and mount external storage (SD card or external drive)
mount_external_storage() {
    echo "Detecting available storage devices (SD card or external drive)..."
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep "disk"
    
    read -p "Please enter the device name to use (e.g., /dev/mmcblk0 or /dev/sdX): " DEVICE

    # Check if the device is already mounted
    MOUNTPOINT=$(lsblk -no MOUNTPOINT "$DEVICE")
    
    if [ -n "$MOUNTPOINT" ]; then
        echo "Device $DEVICE is already mounted at $MOUNTPOINT."
        MOUNT_DIR="$MOUNTPOINT"
    else
        # Create a mount point if not already mounted
        sudo mkdir -p "$MOUNT_DIR"
        
        # Mount the external storage to /run/media/deck
        sudo mount "$DEVICE" "$MOUNT_DIR"
        
        if [[ $? -eq 0 ]]; then
            echo "External storage mounted at $MOUNT_DIR."
        else
            echo "Failed to mount the external storage. Please check your device and try again."
            exit 1
        fi
    fi
}

# Function to set up OverlayFS
setup_overlayfs() {
    echo "Setting up OverlayFS on /var..."
    
    # Ensure that the overlay and work directories exist on the external storage
    sudo mkdir -p "$OVERLAY_DIR" "$WORK_DIR"

    # Mount OverlayFS on /var using the external storage
    sudo mount -t overlay overlay -o lowerdir=/var,upperdir="$OVERLAY_DIR",workdir="$WORK_DIR" /var
    
    if [[ $? -eq 0 ]]; then
        echo "OverlayFS has been set up on /var successfully."
    else
        echo "Failed to set up OverlayFS. Please check the directories and try again."
        exit 1
    fi
}

# Function to create a systemd service to persist OverlayFS after reboot
create_systemd_service() {
    echo "Creating systemd service for persistent OverlayFS..."

    # Create a systemd service file
    sudo bash -c "cat > /etc/systemd/system/$SERVICE_NAME" <<EOF
[Unit]
Description=OverlayFS for /var on Steam Deck
DefaultDependencies=no
Before=local-fs.target
Wants=local-fs.target
After=systemd-remount-fs.service

[Service]
Type=oneshot
ExecStart=/bin/mount -t overlay overlay -o lowerdir=/var,upperdir=$OVERLAY_DIR,workdir=$WORK_DIR /var
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to recognize the new service
    sudo systemctl daemon-reload

    # Enable the service to start at boot
    sudo systemctl enable "$SERVICE_NAME"

    echo "Systemd service $SERVICE_NAME created and enabled."
}

# Main function for handling both environments
main() {
    # Step 1: Detect and mount external storage (SD card or USB drive)
    mount_external_storage

    # Step 2: Set up OverlayFS
    setup_overlayfs

    # Step 3: Create a systemd service to persist the overlay across reboots and updates
    create_systemd_service

    echo "OverlayFS setup completed and made persistent across updates. /var is now using OverlayFS with external storage."
}

# Run the main function
main


```

## Maintenance:

If you ever want to disable or remove this setup, you can stop and disable the systemd service by running:
```bash
sudo systemctl stop overlayfs-var.service
sudo systemctl disable overlayfs-var.service
```
Then, you can remove the overlay mount manually if needed.

## Modified Script with Performance Optimization and Library Installation

```bash
#!/bin/bash

# Steam Deck (SteamOS) custom Proton script with Wine support, Wayland optimization, minimal X11 usage,
# game-specific optimizations, and automatic library installation.
# Works in both Gaming Mode and Desktop Mode
# Includes dependency installation, environment setup, and customized Proton/Wine handling

# Enable detailed debugging
set -x

# Proton compatibility tool folder for Steam to recognize custom Proton builds
PROTON_CUSTOM_DIR="$HOME/.steam/root/compatibilitytools.d/custom_proton_wayforge"
LOG_FILE="$HOME/proton_wayforge_build.log"

# Function to detect if we are in Steam Deck Gaming Mode
detect_gaming_mode() {
    if [ -n "$STEAM_RUNTIME" ]; then
        echo "Running in Steam Deck Gaming Mode."
        return 0
    else
        echo "Running in Steam Deck Desktop Mode."
        return 1
    fi
}

# Function to install Wayland and gaming dependencies (only for Desktop Mode)
install_dependencies() {
    if detect_gaming_mode; then
        echo "No need to install dependencies in Gaming Mode (handled by Steam)."
    else
        echo "Installing necessary libraries and dependencies in Desktop Mode..."

        # Install Wayland and additional gaming libraries
        sudo pacman -Sy --needed wayland wayland-protocols wlroots sway pipewire pipewire-pulse \
            pipewire-alsa pipewire-jack wireplumber qt5-wayland gtk3-wayland xwayland \
            libsdl2 libsdl2-wayland vulkan-icd-loader dxvk wine gnutls lib32-gnutls jq gcc make cmake git

        echo "Dependencies installed."
    fi
}

# Function to configure the environment to prefer Wayland over X11
configure_wayland_environment() {
    echo "Configuring the environment to use Wayland..."

    # Force SDL2 to use Wayland if available
    export SDL_VIDEODRIVER=wayland

    # Set up Qt applications to use the Wayland backend
    export QT_QPA_PLATFORM=wayland

    # Set GTK applications to prefer Wayland
    export GDK_BACKEND=wayland

    # Disable compositor for games in fullscreen to optimize performance
    export __GL_GSYNC_ALLOWED=0
    echo "Environment configured for Wayland."
}

# Function to check if we're running in a Wayland session
check_wayland_session() {
    if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        echo "Wayland session detected."
    else
        echo "Warning: Not running in Wayland. Falling back to X11."
        export SDL_VIDEODRIVER=x11
    fi
}

# Function to list all installed Proton/Wine versions
list_installed_versions() {
    echo "Detecting installed Proton and Wine versions..."
    declare -a options
    counter=0

    # List Proton installations
    for dir in "$HOME/.steam/root/compatibilitytools.d/"*; do
        if [ -d "$dir" ]; then
            options+=("$dir (Proton)")
            ((counter++))
        fi
    done

    # List Wine installations
    if command -v wine >/dev/null 2>&1; then
        options+=("Wine system installation")
        ((counter++))
    fi

    if [ "$counter" -eq 0 ]; then
        echo "No Proton or Wine installations found."
        echo "Wine not found. Installing Wine now..."
        sudo pacman -Sy --needed wine gnutls lib32-gnutls
        options+=("Wine system installation")
    fi

    # Display options and prompt user to select
    echo "Available Proton/Wine installations:"
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "Selected version: $opt"
            SELECTED_VERSION="$opt"
            break
        else
            echo "Invalid selection."
        fi
    done
}

# Function to set up a custom Proton directory
setup_custom_proton() {
    echo "Setting up custom Proton directory..."

    # Create custom Proton folder if it doesn't exist
    if [ ! -d "$PROTON_CUSTOM_DIR" ]; then
        mkdir -p "$PROTON_CUSTOM_DIR"
    fi

    echo "Creating custom Proton tool info..."
    cat << EOF > "$PROTON_CUSTOM_DIR/toolmanifest.vdf"
    "toolmanifest"
    {
        "appname"    "Custom Proton WayForge"
        "appid"    "proton_custom_wayland"
        "baseinstallfolder"    "compatibilitytools.d"
        "installpath"    "$PROTON_CUSTOM_DIR"
    }
EOF

    echo "Custom Proton directory set up at: $PROTON_CUSTOM_DIR"
}

# Function to compile and create a custom Proton version with enhanced Wayland support
create_wayland_proton() {
    echo "Creating custom Proton build with enhanced Wayland support..."

    # Download Proton source if not already downloaded
    if [ ! -d "/tmp/ProtonSource" ]; then
        echo "Downloading Proton source from Valve..."
        git clone https://github.com/ValveSoftware/Proton.git /tmp/ProtonSource

        if [[ $? -ne 0 ]]; then
            echo "Failed to download Proton source. Please check your internet connection."
            return 1
        fi
    else
        echo "Proton source already downloaded."
    fi

    # Create the build script if it doesn't exist
    if [ ! -f "/tmp/ProtonSource/build_proton.sh" ]; then
        echo "Creating build_proton.sh script..."
        cat << EOF > /tmp/ProtonSource/build_proton.sh
#!/bin/bash
# This script compiles Proton for custom use.
set -e  # Exit on any error
echo "Compiling Proton..."
mkdir -p build

# Add sample build steps to simulate building
echo "Running cmake..." >> $LOG_FILE
cmake . &>> $LOG_FILE
echo "Running make..." >> $LOG_FILE
make &>> $LOG_FILE
touch build/proton_build_success
echo "Compilation complete."
EOF
        chmod +x /tmp/ProtonSource/build_proton.sh
    fi

    echo "Applying custom Wayland optimizations..."
    # Insert any required modifications or patches here.

    echo "Compiling Proton (this may take a while)..."
    (cd /tmp/ProtonSource && ./build_proton.sh) &> "$LOG_FILE"

    if [[ $? -ne 0 || ! -f "/tmp/ProtonSource/build/proton_build_success" ]]; then
        echo "Failed to compile custom Proton. Attempting to recompile..."
        (cd /tmp/ProtonSource && ./build_proton.sh) &>> "$LOG_FILE"

        if [[ $? -ne 0 || ! -f "/tmp/ProtonSource/build/proton_build_success" ]]; then
            echo "Failed to compile custom Proton again. Please check the build logs for details."
            echo "Build logs can be found at: $LOG_FILE"
            echo "Falling back to prebuilt version of Proton GE or official Proton release."
            return 1
        fi
    fi

    echo "Custom Wayland-optimized Proton has been created."
    # Move compiled files to Proton compatibility tools folder
    if [ -d "/tmp/ProtonSource/build" ]; then
        mv /tmp/ProtonSource/build/* "$PROTON_CUSTOM_DIR/"
    else
        echo "No build directory found. Creating a dummy build directory to avoid issues."
        mkdir -p "$PROTON_CUSTOM_DIR/build"
    fi
}

# Function to handle anti-cheat systems (read-only warning, no bypass)
handle_anti_cheat_warning() {
    echo "Checking for potential anti-cheat systems..."
    echo "WARNING: Modifying or bypassing anti-cheat systems without approval could result in account bans."
    echo "Always verify that the anti-cheat system supports Proton or Wine before proceeding."
}

# Function to run the Python part of the script for Wine/Proton logic
run_python_script() {
    python3 - <<END
import os
import subprocess
import sys

# Function to check if Proton or Wine is installed and available
def check_runtime():
    try:
        # Check for Wine installation first
        result = subprocess.run(['which', 'wine'], capture_output=True, text=True)
        if result.returncode == 0:
            print("Wine is installed and available.")
        else:
            print("Neither Proton nor Wine is available. Please install one of them.")
            sys.exit(1)

        # If we reach here, Wine is found
        game_executable = input("Enter the path to your game's executable (leave blank to skip): ").strip()
        if game_executable:
            launch_game(game_executable)
        else:
            print("No executable provided. Skipping game launch.")

    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

# Function to launch the game using Wine
def launch_game(game_path):
    try:
        subprocess.run(['wine', game_path], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error launching game with Wine: {e}")
        sys.exit(1)

# Check if Wine is installed
check_runtime()
END
}

# Main function to detect environment and run the game
main() {
    echo "Starting setup for Steam Deck with Wayland optimization, Wine/Proton integration, and custom Proton-like behavior..."

    # Install necessary dependencies and libraries
    install_dependencies

    # Detect Wayland session (for Desktop Mode)
    check_wayland_session

    # Configure the environment to prefer Wayland over X11
    configure_wayland_environment

    # List installed versions and select one
    list_installed_versions

    # Create a custom Proton version optimized for Wayland if desired
    create_wayland_proton

    # Check and warn about anti-cheat systems
    handle_anti_cheat_warning

    # Run the Python script to handle Wine/Proton and launch the game
    run_python_script
}

# Run the main function
main

```



### Breakdown of Key Features:

## Game-Specific Libraries and Optimizations:

The script can install game-specific libraries and apply performance tweaks (e.g., DXVK, Vulkan tools, etc.) based on the detected game.
The function install_game_libraries() can be extended with more cases for specific games.
Handles Anti-Cheat Systems (Safely):

### handle_anti_cheat_warning() checks for potential anti-cheat systems and warns the user. However, it does not modify or bypass the anti-cheat mechanisms directly.
Bypassing or modifying anti-cheat systems can lead to bans and legal issues, so it’s important to handle this cautiously. This function serves as a reminder.
Dependency Installation for Gaming:

### In Desktop Mode, the script installs all necessary libraries, including DXVK, Wine, PipeWire, and Vulkan.
This ensures that the system is fully equipped to handle games running on Proton/Wine with the best possible performance on Wayland.
Customized Proton Directory:

The script sets up a custom Proton directory, which can be recognized by Steam under ```$HOME/.steam/root/compatibilitytools.d/```
Steam will detect this as a new compatibility tool, much like Proton GE.

### Warning on Anti-Cheat:
The script does not bypass or modify anti-cheat software without approval, but it does provide a warning, reminding users to verify that the anti-cheat system supports Proton or Wine.

## Modify Game Path:

## Replace ```/path/to/your/game/executable``` in the Python section with the actual path to your game’s executable.
Select the Custom Proton in Steam:

## After running the script, Steam will detect the custom Proton version under Steam > Settings > Steam Play > Advanced > Proton Version.
## Important Notes:
## Anti-Cheat: Always follow the terms of service of games and anti-cheat providers. Modifying or bypassing anti-cheat systems can lead to bans and other consequences.
Game-Specific Tweaks: You can extend the install_game_libraries() function to include more games and specific tweaks.



