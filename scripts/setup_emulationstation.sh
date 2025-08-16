#!/bin/bash

set -euo pipefail

main() {
    echo "=== RetroPie Installation (Official Method) ==="
    
    # Detect user
    if [[ $EUID -eq 0 ]]; then
        if [[ -n "${SUDO_USER:-}" ]]; then
            REAL_USER="$SUDO_USER" 
            USER_HOME="/home/$SUDO_USER"
        else
            echo "ERROR: No SUDO_USER detected"
            exit 1
        fi
    else
        REAL_USER="$USER"
        USER_HOME="$HOME"
    fi
    
    echo "Installing RetroPie for user: $REAL_USER"
    
    # Step 1: Clone RetroPie Setup
    RETROPIE_DIR="${USER_HOME}/RetroPie-Setup"
    
    if [ -d "$RETROPIE_DIR" ]; then
        rm -rf "$RETROPIE_DIR"
    fi
    
    echo "→ Cloning RetroPie Setup..."
    sudo -u "$REAL_USER" git clone https://github.com/RetroPie/RetroPie-Setup.git "$RETROPIE_DIR"
    
    # Step 2: Run Basic Install
    echo "→ Running RetroPie Basic Install..."
    cd "$RETROPIE_DIR"
    chmod +x retropie_setup.sh
    sudo ./retropie_setup.sh basic_install
    
    # Step 3: Create ROM directories
    echo "→ Creating ROM directories..."
    ROM_DIR="${USER_HOME}/RetroPie/roms"
    
    systems=("nes" "snes" "megadrive" "n64" "psx" "arcade" "gb" "gba" "atari2600")
    
    for system in "${systems[@]}"; do
        mkdir -p "$ROM_DIR/$system"
        echo "Place $system ROMs here" > "$ROM_DIR/$system/README.txt"
    done
    
    chown -R "$REAL_USER:$REAL_USER" "${USER_HOME}/RetroPie"
    
    echo "✓ RetroPie Installation Complete!"
    echo ""
    echo "Add ROMs to: $ROM_DIR/<system>/"
    echo "Reboot to start EmulationStation automatically"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
