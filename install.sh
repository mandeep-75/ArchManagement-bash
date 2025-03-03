#!/bin/bash

# Define paths
SCRIPT_DIR="$HOME/.config/scripts"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

# Function to log messages
log() {
    echo -e "\e[1;32m[INFO]\e[0m $1"
}

clear  # Clear the terminal before running

log "Starting installation..."

# Ensure directories exist
mkdir -p "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR"

# Copy scripts to local bin
log "Copying scripts..."
cp "$SCRIPT_DIR/tui-main.sh" "$BIN_DIR/tui-main"
cp "$SCRIPT_DIR/core_functions.sh" "$BIN_DIR/core_functions"

# Make scripts executable
log "Setting executable permissions..."
chmod +x "$BIN_DIR/tui-main" "$BIN_DIR/core_functions"

# Install .desktop file
log "Installing .desktop file..."
cp "$SCRIPT_DIR/ArchManagement.desktop" "$DESKTOP_DIR/"

# Install icon
log "Installing icon..."
cp "$SCRIPT_DIR/ArchManagement.png" "$ICON_DIR/"

# Update desktop database
log "Updating desktop database..."
update-desktop-database "$DESKTOP_DIR"

log "Installation completed successfully! ✅"
