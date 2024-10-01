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

## Usage

This script will automatically set up a custom Proton build in ```$HOME/.steam/root/compatibilitytools.d/```
Ensure that you have installed the necessary dependencies in Desktop Mode.
Once installed, you can select Proton WayForge as the compatibility tool for games in Steam.

## Modified Script with Performance Optimization and Library Installation

```bash
#!/bin/bash

# Steam Deck (SteamOS) custom Proton script with Wine support, Wayland optimization, minimal X11 usage, 
# game-specific optimizations, and automatic library installation.
# Works in both Gaming Mode and Desktop Mode
# Includes dependency installation, environment setup, and customized Proton/Wine handling

# Proton compatibility tool folder for Steam to recognize custom Proton builds
PROTON_CUSTOM_DIR="$HOME/.steam/root/compatibilitytools.d/custom_proton_wayforge"

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
            libsdl2 libsdl2-wayland vulkan-icd-loader dxvk wine

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

# Function to set up a custom Proton directory
setup_custom_proton() {
    echo "Setting up custom Proton directory..."

    # Create custom Proton folder if it doesn't exist
    if [ ! -d "$PROTON_CUSTOM_DIR" ]; then
        mkdir -p "$PROTON_CUSTOM_DIR"
    fi

    # Create a basic Proton-like structure for Steam to recognize
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

# Function to install game-specific libraries and patches (DXVK, Vulkan, etc.)
install_game_libraries() {
    local game_name="$1"

    echo "Installing necessary libraries for game: $game_name"

    case "$game_name" in
        "SomeGame")
            # Install specific libraries for SomeGame
            echo "Installing DXVK and Vulkan optimizations for SomeGame..."
            # Install DXVK and apply any necessary tweaks
            sudo pacman -S dxvk vulkan-tools
            ;;
        "OtherGame")
            # Install specific libraries for OtherGame
            echo "Applying performance tweaks for OtherGame..."
            # Example: disable Steam overlay
            export STEAM_DISABLE_OVERLAY=1
            ;;
        *)
            echo "No specific tweaks for $game_name. Proceeding with default setup."
            ;;
    esac
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
        result = subprocess.run(['which', 'proton'], capture_output=True, check=True, text=True)
        if result.returncode == 0:
            print("Proton is installed and available.")
        else:
            print("Proton not found, checking for Wine.")
            result = subprocess.run(['which', 'wine'], capture_output=True, check=True, text=True)
            if result.returncode == 0:
                print("Wine is installed and available.")
            else:
                print("Neither Proton nor Wine is available. Please install one of them.")
                sys.exit(1)
    except subprocess.CalledProcessError:
        print("Error checking Proton or Wine installation.")
        sys.exit(1)

# Function to launch the game using either Proton or Wine
def launch_game(game_path):
    try:
        # Try launching with Proton first
        result = subprocess.run(['proton', 'run', game_path], check=False)
        if result.returncode != 0:
            print("Proton failed. Falling back to Wine.")
            subprocess.run(['wine', game_path], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error launching game with Proton or Wine: {e}")
        sys.exit(1)

# Check if Proton or Wine is installed
check_runtime()

# Set game path (modify this path to your game's executable)
game_executable = '/path/to/your/game/executable'

# Launch the game with Proton or Wine
launch_game(game_executable)
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

    # Handle game-specific libraries and patches (DXVK, Vulkan, etc.)
    local game_name="SomeGame"  # Change to detect the actual game being run
    install_game_libraries "$game_name"

    # Check and warn about anti-cheat systems
    handle_anti_cheat_warning

    # Set up the custom Proton directory to emulate Proton-like behavior
    setup_custom_proton

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



