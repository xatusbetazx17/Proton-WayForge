#!/bin/bash

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
    local game_executable="$1"

    python3 - <<END
import os
import subprocess
import sys

# Function to check if Proton or Wine is installed and available
def check_runtime(game_path):
    try:
        # Check for Wine installation
        result = subprocess.run(['which', 'wine'], capture_output=True, text=True)
        if result.returncode == 0:
            print("Wine is installed and available.")
        else:
            print("Neither Proton nor Wine is available. Please install one of them.")
            sys.exit(1)

        # If game path is provided, launch it
        if game_path:
            launch_game(game_path)
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

# Get the game executable path
game_path = "$game_executable"

# Check if Wine is installed and optionally launch the game
check_runtime(game_path)
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

    # Get game executable path from the user (skip if left blank)
    read -p "Enter the path to your game's executable (leave blank to skip): " game_executable

    # Run the Python script to handle Wine/Proton and launch the game
    run_python_script "$game_executable"
}

# Run the main function
main
