#!/bin/bash

# Define paths
INSTALL_DIR="$HOME/.config/scripts"
DESKTOP_DIR="$HOME/.local/share/applications"

#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Current script directory: $script_dir"

echo "Starting installation..."

# Ensure directories exist
echo "Creating necessary directories..."
sudo mkdir -p "$SCRIPT_DIR"  "$DESKTOP_DIR" "$INSTALL_DIR"

# Check if script files exist before proceeding
if [[ ! -f "$SCRIPT_DIR/tui-main.sh" || ! -f "$SCRIPT_DIR/core_functions.sh" || ! -f "$SCRIPT_DIR/ArchManagement.desktop" || ! -f "$SCRIPT_DIR/ArchManagement.png" ]]; then
    echo "Error: One or more required files are missing in $SCRIPT_DIR"
    echo "Please ensure these files exist before running the script."
    exit 1
fi

# Copy scripts to local bin
echo "Copying scripts..."
sudo cp "$SCRIPT_DIR/tui-main.sh" "$INSTALL_DIR"
sudo cp "$SCRIPT_DIR/core_functions.sh" "$INSTALL_DIR"

# Make scripts executable
echo "Setting executable permissions..."
sudo chmod +x "$INSTALL_DIR/tui-main.sh" "$INSTALL_DIR/core_functions.sh"

# Install .desktop file
echo "Installing .desktop file..."
sudo cp "$SCRIPT_DIR/ArchManagement.desktop" "$DESKTOP_DIR/"


echo "Installing icon..."
sudo cp "$SCRIPT_DIR/ArchManagement.png" "$INSTALL_DIR/"
# Update desktop database
echo "Updating desktop database..."
update-desktop-database "$DESKTOP_DIR"

echo "Installation completed successfully! ✅"
