#!/bin/bash

# Define paths
INSTALL_DIR="$HOME/.config/scripts"
FILE_NAME=${BASH_SOURCE[0]}
DESKTOP_DIR="$HOME/.local/share/applications"

#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Current script directory: $script_dir"

echo $BIN_DIR
clear  # Clear the terminal before running

echo "Starting installation..."

# Ensure directories exist
echo "Creating necessary directories..."
mkdir -p "$SCRIPT_DIR"  "$DESKTOP_DIR" 

# Check if script files exist before proceeding
if [[ ! -f "$SCRIPT_DIR/tui-main.sh" || ! -f "$SCRIPT_DIR/core_functions.sh" || ! -f "$SCRIPT_DIR/ArchManagement.desktop" || ! -f "$SCRIPT_DIR/ArchManagement.png" ]]; then
    echo "Error: One or more required files are missing in $SCRIPT_DIR"
    echo "Please ensure these files exist before running the script."
    exit 1
fi

# Copy scripts to local bin
echo "Copying scripts..."
cp "$SCRIPT_DIR/tui-main.sh" "$INSTALL_DIR/tui-main"
cp "$SCRIPT_DIR/core_functions.sh" "$INSTALL_DIR/core_functions"

# Make scripts executable
echo "Setting executable permissions..."
chmod +x "$INSTALL_DIR/tui-main" "$INSTALL_DIR/core_functions"

# Install .desktop file
echo "Installing .desktop file..."
cp "$SCRIPT_DIR/ArchManagement.desktop" "$DESKTOP_DIR/"


echo "Installing icon..."
cp "$SCRIPT_DIR/ArchManagement.png" "$INSTALL_DIR/"
# Update desktop database
echo "Updating desktop database..."
update-desktop-database "$DESKTOP_DIR"

echo "Installation completed successfully! ✅"
