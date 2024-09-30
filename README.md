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
git clone https://github.com/YOUR_GITHUB_USERNAME/Proton-WayForge.git
cd Proton-WayForge
chmod +x proton_wayforge.sh
./proton_wayforge.sh
