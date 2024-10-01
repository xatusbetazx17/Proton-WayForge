# Proton-WayForge
Proton WayForge is a customized version of Proton optimized for Wayland environments on Linux, especially on Steam Deck. It minimizes X11 usage, prioritizes Wayland support, and includes a fallback mechanism to run games with Wine if Proton fails.

## Features
- Wayland optimizations for SDL2, Qt, and GTK applications.
- Custom Proton-like behavior with a directory for easy Steam integration.
- Wine fallback when Proton can't run the game.
- Full support for Steam Deck in both Gaming Mode and Desktop Mode.
- Works out-of-the-box with minimal setup.

## Installation

## 1. Clone this repository :

```bash
git clone https://github.com/xatusbetazx17/Proton-WayForge.git
```
## 2. Create the proton_wayforge.sh Script Using nano
Run the following command to open the nano text editor and create the proton_wayforge.sh file:

```bash
nano proton_WayForge.sh
```
## 3. Save and Exit nano:
   - To save the file in **nano**, press `CTRL + O` (to write out the file) and hit `Enter`.
   - To exit **nano**, press `CTRL + X`.

### 4. Make the Script Executable
Once you've created the script, make it executable with the following command:

```bash
cd Proton-WayForge
chmod +x proton_WayForge.sh
./proton_WayForge.sh
```


## Usage

This script will automatically set up a custom Proton build in ```$HOME/.steam/root/compatibilitytools.d/```
Ensure that you have installed the necessary dependencies in Desktop Mode.
Once installed, you can select Proton WayForge as the compatibility tool for games in Steam.

## Modified Script with Performance Optimization and Library Installation

```bash
#!/bin/bash

# Arch Linux ISO and Balena Etcher AppImage download URLs
ARCH_ISO_URL="https://mirrors.edge.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso"
ARCH_ISO_PATH="$HOME/archlinux.iso"
ETCHER_APPIMAGE_URL="https://github.com/balena-io/etcher/releases/download/v1.5.122/balenaEtcher-1.5.122-x64.AppImage"
ETCHER_APPIMAGE_PATH="$HOME/balenaEtcher.AppImage"

# Function to detect if we are in SteamOS or Arch Linux Live environment
detect_environment() {
    if grep -q "SteamOS" /etc/os-release; then
        echo "Running in SteamOS."
        IS_STEAMOS=1
    elif grep -q "ARCH" /etc/os-release; then
        echo "Running in Arch Linux live environment."
        IS_STEAMOS=0
    else
        echo "Unknown environment. Exiting."
        exit 1
    fi
}

# Function to download the Arch Linux ISO
download_arch_iso() {
    echo "Downloading the latest Arch Linux ISO..."
    wget -O "$ARCH_ISO_PATH" "$ARCH_ISO_URL"

    if [[ $? -eq 0 ]]; then
        echo "Arch Linux ISO downloaded successfully to $ARCH_ISO_PATH."
    else
        echo "Failed to download the Arch Linux ISO. Please check your connection."
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

# Function to launch Balena Etcher
launch_etcher() {
    echo "Launching Balena Etcher..."
    "$ETCHER_APPIMAGE_PATH" &
    
    if [[ $? -eq 0 ]]; then
        echo "Balena Etcher launched successfully. Please use the GUI to flash the Arch Linux ISO to the USB drive."
    else
        echo "Failed to launch Balena Etcher."
        exit 1
    fi
}

# Function to prompt the user to reboot manually into the USB
prompt_reboot() {
    echo -e "\n###########################################"
    echo "Arch Linux live USB has been prepared."
    echo "Please reboot your Steam Deck and boot from the USB drive."
    echo "Once you are booted into the Arch Linux live environment, run this script again."
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

# Function to run GParted for partition resizing
resize_var_partition() {
    echo "Opening GParted for partition resizing..."
    sudo gparted
    echo "Once partition resizing is done, reboot into SteamOS."
}

# Main function for handling both environments
main() {
    # Detect if we are in SteamOS or Arch Linux live environment
    detect_environment

    if [[ $IS_STEAMOS -eq 1 ]]; then
        # If we are in SteamOS, download the ISO and Balena Etcher, and launch Etcher
        download_arch_iso
        download_etcher_appimage
        launch_etcher
        prompt_reboot
    else
        # If we are in Arch Linux live environment, install tools and resize partitions
        install_tools_in_live_env
        resize_var_partition
    fi
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



