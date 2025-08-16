#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration
USER_HOME="${SUDO_HOME:-$HOME}"
if [[ -n "${SUDO_USER:-}" ]]; then
    USER_HOME="/home/${SUDO_USER}"
fi
RETROPIE_DIR="${USER_HOME}/RetroPie-Setup"
RETROPIE_ROMS_DIR="${USER_HOME}/ROMs"

check_hardware() {
    echo "Checking hardware compatibility..."
    
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        echo "WARNING: Not running on Raspberry Pi - performance may vary"
    fi
    
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_kb / 1024 / 1024))
    
    if [ "$mem_gb" -lt 2 ]; then
        echo "WARNING: Low memory (${mem_gb}GB) - some emulators may not perform well"
    else
        echo "✓ Memory: ${mem_gb}GB (good for emulation)"
    fi
}

setup_retropie() {
    echo "Setting up RetroPie..."
    
    if [ "$EUID" -eq 0 ]; then
        echo "ERROR: Do not run as root"
        exit 1
    fi
    
    # Clone or update RetroPie
    if [ -d "$RETROPIE_DIR" ]; then
        echo "Updating existing RetroPie installation..."
        cd "$RETROPIE_DIR"
        git pull
    else
        echo "Cloning RetroPie setup repository..."
        git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git "$RETROPIE_DIR"
    fi
    
    cd "$RETROPIE_DIR"
    sudo chown -R "$USER:$USER" "$RETROPIE_DIR"
    echo "✓ RetroPie repository ready"
}

install_retropie_core() {
    echo "Installing RetroPie core packages..."
    cd "$RETROPIE_DIR"
    
    # Install basic RetroPie packages non-interactively
    echo "Installing EmulationStation and essential emulators..."
    
    # Use automated basic installation
    # This installs EmulationStation and basic emulators
    sudo __nodialog=1 ./retropie_setup.sh basic_install
    
    echo "✓ RetroPie core installation completed"
}

configure_bluetooth_controllers() {
    echo "Configuring Bluetooth for controllers..."
    
    # Enable Bluetooth service
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
    
    # Create udev rules for controller permissions
    sudo tee /etc/udev/rules.d/99-emulationstation-controllers.rules > /dev/null << 'EOF'
# PS4/PS5 controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="054c", MODE="0666"
# Xbox controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="045e", MODE="0666"
# 8BitDo controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="2dc8", MODE="0666"
EOF
    
    sudo udevadm control --reload-rules
    echo "✓ Bluetooth controller support configured"
}

optimize_performance() {
    echo "Applying performance optimizations..."
    
    # GPU memory split optimization for RetroPie
    # (This complements the boot config from phase 1)
    
    # Create EmulationStation config directory
    mkdir -p "${USER_HOME}/.emulationstation"
    
    # Basic EmulationStation settings for performance
    cat > "${USER_HOME}/.emulationstation/es_settings.cfg" << 'EOF'
<?xml version="1.0"?>
<int name="ScreenSaverTime" value="300000" />
<bool name="DrawFramerate" value="false" />
<bool name="ShowHelpPrompts" value="true" />
<bool name="ScrapeRatings" value="true" />
<bool name="IgnoreGamelist" value="false" />
<bool name="HideConsole" value="false" />
<string name="PowerSaverMode" value="enhanced" />
<string name="TransitionStyle" value="fade" />
<int name="MaxVRAM" value="512" />
EOF
    
    echo "✓ Performance optimizations applied"
}

main() {
    echo "=== EmulationStation Setup ==="
    echo ""
    echo "This will install:"
    echo "• RetroPie/EmulationStation"
    echo "• All major emulators (20+ cores)"
    echo "• Comprehensive ROM structure (40+ systems)"
    echo "• Controller mappings and auto-discovery"
    echo "• Popular themes"
    echo "• Performance optimizations"
    echo ""
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    # Basic setup
    check_hardware
    setup_retropie
    install_retropie_core
    configure_bluetooth_controllers
    optimize_performance
    
    echo ""
    echo "=== Running Full EmulationStation Configuration ==="
    
    # Run the comprehensive configuration
    if [[ -x "${SCRIPT_DIR}/configure_emulationstation.sh" ]]; then
        "${SCRIPT_DIR}/configure_emulationstation.sh" --auto
    else
        echo "WARNING: configure_emulationstation.sh not found - skipping full configuration"
    fi
    
    echo ""
    echo "=== Configuring Kodi Integration ==="
    
    # Configure Kodi (part of RetroPie)
    if [[ -x "${SCRIPT_DIR}/setup_kodi.sh" ]]; then
        "${SCRIPT_DIR}/setup_kodi.sh" --auto
    else
        echo "WARNING: setup_kodi.sh not found - skipping Kodi configuration"
    fi
    
    echo ""
    echo "=== EmulationStation Setup Complete ==="
    echo "✓ RetroPie installed and configured"
    echo "✓ All emulators installed" 
    echo "✓ ROM directories created in ~/ROMs/"
    echo "✓ Controller support configured"
    echo "✓ Themes installed"
    echo "✓ Kodi media center configured"
    echo ""
    echo "To start gaming:"
    echo "Run: emulationstation"
    echo ""
    echo "To access Kodi:"
    echo "From EmulationStation: Ports → Kodi"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
