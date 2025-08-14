#!/bin/bash

# EmulationStation with Automatic Controller Support Setup Script
# This script installs RetroPie with all major emulators and experimental features
# Includes comprehensive automatic controller discovery, pairing, and mapping
# Optional Kodi integration available via separate script

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration - User-specific installation
RETROPIE_DIR="$HOME/RetroPie-Setup"
RETROPIE_CONFIG_DIR="$HOME/.emulationstation"
RETROPIE_ROMS_DIR="$HOME/ROMs"  # Place ROMs alongside Documents, Downloads, etc.
KODI_PORT_DIR="$HOME/ROMs/ports"

log_info "Starting EmulationStation Setup with Automatic Controller Support for user $USER"

# Function to check if we're running on supported hardware
check_hardware() {
    log_info "Checking hardware compatibility..."
    
    # Check for Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        log_warn "This script is optimized for Raspberry Pi hardware"
    fi
    
    # Check architecture
    local arch=$(uname -m)
    case "$arch" in
        aarch64|armv7l|x86_64)
            log_info "Architecture: $arch (supported)"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    # Check available memory
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_kb / 1024 / 1024))
    
    if [ "$mem_gb" -lt 2 ]; then
        log_warn "Low memory detected (${mem_gb}GB). Some emulators may not perform well."
    else
        log_info "Memory: ${mem_gb}GB (good for emulation)"
    fi
}

# Function to install system dependencies
install_dependencies() {
    log_info "Installing system dependencies for RetroPie..."
    
    # Update package list
    sudo apt update
    
    # Essential packages for RetroPie compilation
    local packages=(
        "git"
        "dialog"
        "unzip"
        "xmlstarlet"
        "build-essential"
        "cmake"
        "libasound2-dev"
        "libfreeimage-dev"
        "libfreetype6-dev"
        "libcurl4-openssl-dev"
        "rapidjson-dev"
        "libeigen3-dev"
        "libvlc-dev"
        "vlc"
        "libsdl2-dev"
        "libboost-all-dev"
        "python3-dev"
        "python3-pip"
        "python3-setuptools"
        "libfftw3-dev"
        "libraspberrypi-dev"
    )
    
    # Install packages with error handling
    for package in "${packages[@]}"; do
        if ! sudo apt install -y "$package"; then
            log_warn "Failed to install $package, continuing..."
        fi
    done
    
    log_info "System dependencies installed"
}

# Function to install controller support packages
install_controller_dependencies() {
    log_info "Installing controller support packages..."
    
    # Controller and input packages
    local controller_packages=(
        # Bluetooth support
        "bluetooth"
        "bluez"
        "bluez-tools"
        "bluez-hcidump"
        "libbluetooth-dev"
        
        # Input device support
        "joystick"
        "jstest-gtk"
        "evtest"
        "input-utils"
        "xboxdrv"
        
        # SDL2 controller support
        "libsdl2-dev"
        "libsdl2-image-dev"
        "libsdl2-mixer-dev"
        "libsdl2-ttf-dev"
        
        # Python packages for controller management
        "python3-evdev"
        "python3-pygame"
        "python3-pybluez"
        
        # Additional input libraries
        "libudev-dev"
        "libusb-1.0-0-dev"
        "libhidapi-dev"
    )
    
    # Install controller packages
    for package in "${controller_packages[@]}"; do
        if sudo apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package (continuing...)"
        fi
    done
    
    # Install additional Python packages via pip
    log_info "Installing Python controller libraries..."
    pip3 install --user evdev approxeng.input ds4drv || log_warn "Some Python packages failed to install"
    
    log_success "Controller support packages installed"
}

# Function to download and setup RetroPie
setup_retropie() {
    log_info "Setting up RetroPie for user: $USER"
    
    # Ensure we're running as the correct user (not root)
    if [ "$EUID" -eq 0 ]; then
        log_error "This script should not be run as root for RetroPie installation"
        log_error "RetroPie should be installed for the regular user account"
        log_error "Please run this script as your normal user with sudo when needed"
        exit 1
    fi
    
    # Verify user directories exist
    if [ ! -d "$HOME" ]; then
        log_error "User home directory not found: $HOME"
        exit 1
    fi
    
    # Clone RetroPie setup repository
    if [ -d "$RETROPIE_DIR" ]; then
        log_info "RetroPie directory exists, updating..."
        cd "$RETROPIE_DIR"
        git pull
    else
        log_info "Cloning RetroPie setup repository for user $USER..."
        git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git "$RETROPIE_DIR"
    fi
    
    cd "$RETROPIE_DIR"
    
    # Ensure proper ownership of RetroPie directory
    sudo chown -R "$USER:$USER" "$RETROPIE_DIR"
    
    log_info "RetroPie setup repository ready for user $USER"
}

# Function to create automated installation script for RetroPie packages
create_retropie_install_script() {
    log_info "Creating automated RetroPie installation script..."
    
    # Create expect script for automated installation
    cat > "/tmp/retropie_auto_install.exp" << 'EOF'
#!/usr/bin/expect -f

set timeout 3600
spawn sudo ./retropie_setup.sh

# Main menu
expect "Choose an option"
send "P\r"

# Packages menu
expect "Choose an option"
send "\r"

# Install all core packages first
expect "Choose an option"
send "1\r"

# Wait for core installation to complete
expect "Choose an option" {
    send "2\r"
    exp_continue
}

# Main packages installation
expect "Choose an option" {
    # Go back to main packages menu
    send "2\r"
    exp_continue
}

# Exit packages menu
expect "Choose an option"
send "B\r"

# Back to main menu
expect "Choose an option"
send "X\r"

EOF

    chmod +x "/tmp/retropie_auto_install.exp"
}

# Function to install RetroPie core and main packages
install_retropie_packages() {
    log_info "Installing RetroPie core packages for user $USER..."
    
    cd "$RETROPIE_DIR"
    
    # Install core packages (basic setup) - sudo needed but installs for current user
    log_info "Installing basic RetroPie setup for $USER..."
    sudo -E ./retropie_setup.sh <<< $'P\n1\nY\n'
    
    # Ensure proper ownership of installed files
    log_info "Setting proper ownership of RetroPie files..."
    sudo chown -R "$USER:$USER" "$HOME/RetroPie" 2>/dev/null || true
    sudo chown -R "$USER:$USER" "$HOME/.emulationstation" 2>/dev/null || true
    sudo chown -R "$USER:$USER" "$HOME/RetroPie-Setup" 2>/dev/null || true
    
    log_info "Core packages installation completed for user $USER"
}

# Function to install all major emulators and experimental packages
install_emulators() {
    log_info "Installing emulators and experimental packages..."
    
    cd "$RETROPIE_DIR"
    
    # List of emulators and packages to install
    # Format: package_name description
    local emulator_packages=(
        # Main emulators
        "lr-beetle-psx-hw:PlayStation 1 emulator with hardware rendering"
        "lr-beetle-saturn:Sega Saturn emulator"
        "lr-beetle-supergrafx:PC Engine SuperGrafx emulator"
        "lr-bluemsx:MSX/MSX2/Colecovision emulator"
        "lr-cap32:Amstrad CPC emulator"
        "lr-desmume:Nintendo DS emulator"
        "lr-dolphin:GameCube/Wii emulator (experimental)"
        "lr-flycast:Dreamcast/Naomi emulator"
        "lr-fuse:ZX Spectrum emulator"
        "lr-gambatte:Game Boy/Game Boy Color emulator"
        "lr-genesis-plus-gx:Sega Genesis/Mega Drive emulator"
        "lr-handy:Atari Lynx emulator"
        "lr-mame2003-plus:MAME 2003 Plus arcade emulator"
        "lr-mame2010:MAME 2010 arcade emulator"
        "lr-mame2016:MAME 2016 arcade emulator"
        "lr-mgba:Game Boy Advance emulator"
        "lr-mupen64plus-next:Nintendo 64 emulator"
        "lr-nestopia:Nintendo NES emulator"
        "lr-o2em:Odyssey2/Videopac emulator"
        "lr-pcsx-rearmed:PlayStation 1 emulator"
        "lr-picodrive:Sega 32X/Genesis/Game Gear/Master System emulator"
        "lr-ppsspp:PlayStation Portable emulator"
        "lr-prosystem:Atari 7800 emulator"
        "lr-reicast:Dreamcast emulator (legacy)"
        "lr-snes9x:Super Nintendo emulator"
        "lr-stella2014:Atari 2600 emulator"
        "lr-vecx:Vectrex emulator"
        "lr-virtualjaguar:Atari Jaguar emulator"
        "lr-yabause:Sega Saturn emulator (alternative)"
        
        # Experimental emulators
        "lr-beetle-pce-fast:PC Engine/TurboGrafx-16 emulator"
        "lr-beetle-wswan:WonderSwan emulator"
        "lr-bsnes:Super Nintendo emulator (accuracy core)"
        "lr-citra:Nintendo 3DS emulator (experimental)"
        "lr-flycast-wince:Dreamcast Windows CE games"
        "lr-kronos:Sega Saturn emulator (experimental)"
        "lr-parallel-n64:Nintendo 64 parallel processing emulator"
        "lr-puae:Amiga emulator (P-UAE)"
        "lr-redream:Dreamcast emulator (alternative)"
        "lr-same_cdi:Philips CD-i emulator"
        "lr-vice:Commodore 64/128/VIC-20/Plus4 emulator"
        
        # Standalone emulators (better performance for some systems)
        "advmame:AdvanceMAME (optimized MAME)"
        "amiberry:Amiga emulator (standalone)"
        "citra:Nintendo 3DS emulator (standalone)"
        "dolphin:GameCube/Wii emulator (standalone)"
        "dosbox:DOS emulator"
        "drastic:Nintendo DS emulator (commercial)"
        "hatari:Atari ST/STE/TT/Falcon emulator"
        "mupen64plus:Nintendo 64 emulator (standalone)"
        "ppsspp:PlayStation Portable emulator (standalone)"
        "redream:Dreamcast emulator (standalone)"
        "reicast:Dreamcast emulator (standalone, legacy)"
        "scummvm:SCUMM game engine"
        "uae4arm:Amiga emulator"
        "vice:Commodore emulator (standalone)"
        "zdoom:Doom engine"
        
        # Ports and additional software
        "kodi:Media center integration"
        "chromium:Web browser"
        "minecraft-pi:Minecraft Pi Edition"
        "alephone:Marathon game engine"
        "cannonball:OutRun engine"
        "crispy-doom:Doom source port"
        "opentyrian:Tyrian 2000 game"
        "solarus:Action-RPG game engine"
        "supertux:Super Tux platform game"
        "wolf4sdl:Wolfenstein 3D engine"
    )
    
    # Install each package
    for package_info in "${emulator_packages[@]}"; do
        local package_name="${package_info%%:*}"
        local description="${package_info#*:}"
        
        log_info "Installing $package_name for user $USER: $description"
        
        # Use the RetroPie setup script to install the package (preserves user environment)
        if sudo -E ./retropie_setup.sh <<< $'P\n2\n'"$package_name"$'\nY\n'; then
            log_success "Successfully installed $package_name for $USER"
        else
            log_warn "Failed to install $package_name, continuing..."
        fi
        
        # Ensure proper ownership after installation
        sudo chown -R "$USER:$USER" "$HOME/RetroPie" 2>/dev/null || true
        sudo chown -R "$USER:$USER" "$HOME/.emulationstation" 2>/dev/null || true
        
        # Small delay to prevent overwhelming the system
        sleep 2
    done
    
    # Final ownership check
    log_info "Ensuring all RetroPie files belong to user $USER..."
    sudo chown -R "$USER:$USER" "$HOME/RetroPie" 2>/dev/null || true
    sudo chown -R "$USER:$USER" "$HOME/.emulationstation" 2>/dev/null || true
    sudo chown -R "$USER:$USER" "$RETROPIE_ROMS_DIR" 2>/dev/null || true
}

# Function to configure comprehensive controller support
configure_controller_support() {
    log_info "Configuring comprehensive controller support..."
    
    # Configure Bluetooth for controllers
    configure_bluetooth_for_controllers
    
    # Set up automatic controller discovery
    setup_controller_discovery
    
    # Create default controller mappings
    create_controller_mappings
    
    # Configure controller auto-pairing
    setup_controller_autopairing
    
    log_success "Controller support configuration completed"
}

# Function to configure Bluetooth specifically for gaming controllers
configure_bluetooth_for_controllers() {
    log_info "Configuring Bluetooth for gaming controllers..."
    
    # Enable Bluetooth service
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
    
    # Disable ERTM (Enhanced Retransmission Mode) for Xbox controllers
    echo 'options bluetooth disable_ertm=Y' | sudo tee /etc/modprobe.d/xbox_bt.conf
    
    # Configure Bluetooth main settings for gaming
    sudo mkdir -p /etc/bluetooth/main.conf.d
    cat > /tmp/bluetooth_gaming.conf << 'EOF'
[General]
# Gaming controller optimizations
Class=0x000104
DiscoverableTimeout=0
PairableTimeout=0

[Policy]
AutoEnable=true
EOF
    sudo mv /tmp/bluetooth_gaming.conf /etc/bluetooth/main.conf.d/gaming.conf
    
    # Restart Bluetooth to apply changes
    sudo systemctl restart bluetooth
    
    log_info "Bluetooth configured for gaming controllers"
}

# Function to set up automatic controller discovery
setup_controller_discovery() {
    log_info "Setting up automatic controller discovery..."
    
    # Create controller discovery script
    cat > /tmp/controller-discovery.py << 'EOF'
#!/usr/bin/env python3
"""
Automatic Controller Discovery and Configuration Script
Detects connected controllers and creates basic mappings
"""

import subprocess
import json
import os
import time
import glob

def detect_usb_controllers():
    """Detect USB controllers using lsusb"""
    controllers = []
    try:
        result = subprocess.run(['lsusb'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        
        controller_keywords = [
            'Xbox', 'PlayStation', 'DualShock', 'Wireless Controller',
            'Logitech', 'Nintendo', 'Pro Controller', 'Joy-Con',
            'Gamepad', 'Controller', '8BitDo'
        ]
        
        for line in lines:
            for keyword in controller_keywords:
                if keyword.lower() in line.lower():
                    controllers.append({
                        'type': 'USB',
                        'name': line.split('ID ')[1] if 'ID ' in line else line,
                        'detected_type': keyword
                    })
                    break
    except Exception as e:
        print(f"Error detecting USB controllers: {e}")
    
    return controllers

def detect_bluetooth_controllers():
    """Detect paired Bluetooth controllers"""
    controllers = []
    try:
        result = subprocess.run(['bluetoothctl', 'devices'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        
        for line in lines:
            if 'Device' in line:
                parts = line.split(' ', 2)
                if len(parts) >= 3:
                    controllers.append({
                        'type': 'Bluetooth',
                        'mac': parts[1],
                        'name': parts[2]
                    })
    except Exception as e:
        print(f"Error detecting Bluetooth controllers: {e}")
    
    return controllers

def detect_js_devices():
    """Detect joystick devices in /dev/input/js*"""
    devices = []
    js_devices = glob.glob('/dev/input/js*')
    
    for device in js_devices:
        try:
            # Get device name using jstest
            result = subprocess.run(['jstest', '--print-mappings', device], 
                                 capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                devices.append({
                    'device': device,
                    'info': result.stdout.strip()
                })
        except Exception as e:
            devices.append({
                'device': device,
                'info': f'Error reading device: {e}'
            })
    
    return devices

def main():
    print("=== Controller Discovery Report ===")
    print(f"Scan time: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Detect all controller types
    usb_controllers = detect_usb_controllers()
    bt_controllers = detect_bluetooth_controllers()
    js_devices = detect_js_devices()
    
    # Report findings
    print("USB Controllers:")
    if usb_controllers:
        for ctrl in usb_controllers:
            print(f"  ✓ {ctrl['detected_type']}: {ctrl['name']}")
    else:
        print("  No USB controllers detected")
    
    print("\nBluetooth Controllers:")
    if bt_controllers:
        for ctrl in bt_controllers:
            print(f"  ✓ {ctrl['name']} ({ctrl['mac']})")
    else:
        print("  No Bluetooth controllers paired")
    
    print("\nJoystick Devices:")
    if js_devices:
        for device in js_devices:
            print(f"  ✓ {device['device']}")
    else:
        print("  No joystick devices found")
    
    # Save report
    report = {
        'timestamp': time.time(),
        'usb_controllers': usb_controllers,
        'bluetooth_controllers': bt_controllers,
        'joystick_devices': js_devices
    }
    
    os.makedirs('/home/pi/RetroPie/controller_reports', exist_ok=True)
    with open('/home/pi/RetroPie/controller_reports/latest.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\nReport saved to: /home/pi/RetroPie/controller_reports/latest.json")
    return len(usb_controllers) + len(bt_controllers) + len(js_devices)

if __name__ == "__main__":
    main()
EOF
    
    sudo mv /tmp/controller-discovery.py /usr/local/bin/controller-discovery.py
    sudo chmod +x /usr/local/bin/controller-discovery.py
    
    log_info "Controller discovery script installed"
}

# Function to create comprehensive controller mappings
create_controller_mappings() {
    log_info "Creating default controller mappings..."
    
    # Ensure inputconfigs directory exists
    mkdir -p "$RETROPIE_CONFIG_DIR/inputconfigs"
    
    # Xbox Wireless Controller (most common)
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Xbox Wireless Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Xbox Wireless Controller" deviceGUID="030000005e040000e002000000007200">
    <input name="a" type="button" id="0" value="1" />
    <input name="b" type="button" id="1" value="1" />
    <input name="x" type="button" id="2" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="4" value="1" />
    <input name="guide" type="button" id="5" value="1" />
    <input name="start" type="button" id="6" value="1" />
    <input name="leftstick" type="button" id="7" value="1" />
    <input name="rightstick" type="button" id="8" value="1" />
    <input name="leftshoulder" type="button" id="9" value="1" />
    <input name="rightshoulder" type="button" id="10" value="1" />
    <input name="dpup" type="button" id="11" value="1" />
    <input name="dpdown" type="button" id="12" value="1" />
    <input name="dpleft" type="button" id="13" value="1" />
    <input name="dpright" type="button" id="14" value="1" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF
    
    # PlayStation 4/5 DualSense Controller
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Wireless Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Wireless Controller" deviceGUID="030000004c050000cc09000000810000">
    <input name="a" type="button" id="1" value="1" />
    <input name="b" type="button" id="2" value="1" />
    <input name="x" type="button" id="0" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="8" value="1" />
    <input name="guide" type="button" id="12" value="1" />
    <input name="start" type="button" id="9" value="1" />
    <input name="leftstick" type="button" id="10" value="1" />
    <input name="rightstick" type="button" id="11" value="1" />
    <input name="leftshoulder" type="button" id="4" value="1" />
    <input name="rightshoulder" type="button" id="5" value="1" />
    <input name="dpup" type="hat" id="0" value="1" />
    <input name="dpdown" type="hat" id="0" value="4" />
    <input name="dpleft" type="hat" id="0" value="8" />
    <input name="dpright" type="hat" id="0" value="2" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="5" value="1" />
    <input name="lefttrigger" type="axis" id="3" value="1" />
    <input name="righttrigger" type="axis" id="4" value="1" />
</inputConfig>
EOF
    
    # Nintendo Switch Pro Controller
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Pro Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Pro Controller" deviceGUID="030000007e0500000920000000000000">
    <input name="a" type="button" id="0" value="1" />
    <input name="b" type="button" id="1" value="1" />
    <input name="x" type="button" id="2" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="4" value="1" />
    <input name="guide" type="button" id="5" value="1" />
    <input name="start" type="button" id="6" value="1" />
    <input name="leftstick" type="button" id="7" value="1" />
    <input name="rightstick" type="button" id="8" value="1" />
    <input name="leftshoulder" type="button" id="9" value="1" />
    <input name="rightshoulder" type="button" id="10" value="1" />
    <input name="dpup" type="hat" id="0" value="1" />
    <input name="dpdown" type="hat" id="0" value="4" />
    <input name="dpleft" type="hat" id="0" value="8" />
    <input name="dpright" type="hat" id="0" value="2" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF
    
    # 8BitDo SN30 Pro (popular retro controller)
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/8BitDo SN30 Pro.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="8BitDo SN30 Pro" deviceGUID="030000003512000020ab000000010000">
    <input name="a" type="button" id="1" value="1" />
    <input name="b" type="button" id="0" value="1" />
    <input name="x" type="button" id="4" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="10" value="1" />
    <input name="guide" type="button" id="2" value="1" />
    <input name="start" type="button" id="11" value="1" />
    <input name="leftstick" type="button" id="13" value="1" />
    <input name="rightstick" type="button" id="14" value="1" />
    <input name="leftshoulder" type="button" id="6" value="1" />
    <input name="rightshoulder" type="button" id="7" value="1" />
    <input name="dpup" type="hat" id="0" value="1" />
    <input name="dpdown" type="hat" id="0" value="4" />
    <input name="dpleft" type="hat" id="0" value="8" />
    <input name="dpright" type="hat" id="0" value="2" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF
    
    log_success "Default controller mappings created"
}

# Function to set up controller auto-pairing service
setup_controller_autopairing() {
    log_info "Setting up controller auto-pairing service..."
    
    # Create auto-pairing script
    cat > /tmp/controller-autopair.py << 'EOF'
#!/usr/bin/env python3
"""
Controller Auto-Pairing Service
Automatically detects and pairs common gaming controllers
"""

import subprocess
import time
import sys
import os

def run_command(cmd, timeout=10):
    """Run a command with timeout"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"

def enable_bluetooth_discoverable():
    """Make the Pi discoverable for pairing"""
    commands = [
        "bluetoothctl agent on",
        "bluetoothctl default-agent", 
        "bluetoothctl discoverable on",
        "bluetoothctl pairable on"
    ]
    
    for cmd in commands:
        success, stdout, stderr = run_command(cmd)
        if not success:
            print(f"Warning: {cmd} failed: {stderr}")

def scan_for_controllers():
    """Scan for controllers and attempt auto-pairing"""
    print("Scanning for controllers...")
    
    # Start scanning
    run_command("bluetoothctl scan on")
    time.sleep(10)  # Scan for 10 seconds
    run_command("bluetoothctl scan off")
    
    # Get discovered devices
    success, stdout, stderr = run_command("bluetoothctl devices")
    if not success:
        return []
    
    devices = []
    for line in stdout.split('\n'):
        if 'Device' in line:
            parts = line.split(' ', 2)
            if len(parts) >= 3:
                mac = parts[1]
                name = parts[2]
                
                # Check if it's a gaming controller
                controller_keywords = ['xbox', 'playstation', 'controller', 'gamepad', 
                                     'joy-con', 'pro controller', '8bitdo', 'dualsense']
                
                if any(keyword in name.lower() for keyword in controller_keywords):
                    devices.append((mac, name))
    
    return devices

def pair_controller(mac, name):
    """Attempt to pair a controller"""
    print(f"Attempting to pair: {name} ({mac})")
    
    commands = [
        f"bluetoothctl pair {mac}",
        f"bluetoothctl trust {mac}",
        f"bluetoothctl connect {mac}"
    ]
    
    for cmd in commands:
        success, stdout, stderr = run_command(cmd, timeout=30)
        if success:
            print(f"✓ {cmd} succeeded")
        else:
            print(f"✗ {cmd} failed: {stderr}")
            if "pair" in cmd:
                return False
    
    return True

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--scan-only":
        # Just scan and report
        enable_bluetooth_discoverable()
        controllers = scan_for_controllers()
        
        if controllers:
            print(f"Found {len(controllers)} potential controllers:")
            for mac, name in controllers:
                print(f"  • {name} ({mac})")
        else:
            print("No controllers detected")
        return
    
    print("=== Controller Auto-Pairing Service ===")
    print("Put your controller in pairing mode now...")
    print("Waiting 5 seconds for you to press the pairing button...")
    time.sleep(5)
    
    enable_bluetooth_discoverable()
    controllers = scan_for_controllers()
    
    if not controllers:
        print("No controllers detected. Make sure your controller is in pairing mode.")
        return
    
    print(f"Found {len(controllers)} potential controllers:")
    for mac, name in controllers:
        print(f"Attempting to pair: {name}")
        if pair_controller(mac, name):
            print(f"✓ Successfully paired {name}")
        else:
            print(f"✗ Failed to pair {name}")

if __name__ == "__main__":
    main()
EOF
    
    sudo mv /tmp/controller-autopair.py /usr/local/bin/controller-autopair.py
    sudo chmod +x /usr/local/bin/controller-autopair.py
    
    # Create systemd service for auto-pairing
    cat > /tmp/controller-autopair.service << 'EOF'
[Unit]
Description=Gaming Controller Auto-Pairing Service
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/controller-autopair.py --scan-only
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF
    
    sudo mv /tmp/controller-autopair.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable controller-autopair.service
    
    log_success "Controller auto-pairing service configured"
}

# Function to configure Kodi integration (now handled by separate script)
configure_kodi_integration() {
    log_info "Running separate Kodi integration setup..."
    
    # Check if Kodi setup script exists
    local kodi_script="${SCRIPT_DIR}/setup_kodi.sh"
    
    if [ -f "$kodi_script" ]; then
        log_info "Launching Kodi setup script..."
        bash "$kodi_script"
    else
        log_warn "Kodi setup script not found at $kodi_script"
        log_info "You can install Kodi integration separately later"
        
        # Create minimal Kodi port entry as fallback
        mkdir -p "$KODI_PORT_DIR"
        cat > "$KODI_PORT_DIR/Install_Kodi.sh" << 'EOF'
#!/bin/bash
echo "To install Kodi integration:"
echo "Run: cd ~/RaspiCommandCenter/scripts && ./setup_kodi.sh"
read -p "Press Enter to continue..."
EOF
        chmod +x "$KODI_PORT_DIR/Install_Kodi.sh"
    fi
}

# Function to optimize EmulationStation configuration
optimize_emulationstation() {
    log_info "Optimizing EmulationStation configuration..."
    
    # Create .emulationstation directory if it doesn't exist
    mkdir -p "$RETROPIE_CONFIG_DIR"
    
    # Configure es_settings.cfg for optimal performance
    cat > "$RETROPIE_CONFIG_DIR/es_settings.cfg" << 'EOF'
<?xml version="1.0"?>
<es_settings>
    <!-- Video Settings -->
    <bool name="VideoAudio" value="true" />
    <bool name="VideoOmxPlayer" value="true" />
    <bool name="ScreenSaverVideoMute" value="false" />
    <int name="ScreenSaverTime" value="300000" />
    <bool name="SlideshowScreenSaverStretch" value="false" />
    
    <!-- Performance Settings -->
    <bool name="DrawFramerate" value="false" />
    <bool name="ShowHelpPrompts" value="true" />
    <bool name="ScrapeRatings" value="true" />
    <bool name="IgnoreGamelist" value="false" />
    <bool name="HideConsole" value="false" />
    <bool name="QuickSystemSelect" value="true" />
    <bool name="MoveCarousel" value="true" />
    <bool name="SaveGamelistsOnExit" value="true" />
    
    <!-- UI Settings -->
    <string name="ThemeSet" value="carbon" />
    <string name="TransitionStyle" value="slide" />
    <bool name="EnableSounds" value="true" />
    <string name="GamelistViewStyle" value="automatic" />
    <bool name="ShowHidden" value="false" />
    
    <!-- Collection Settings -->
    <bool name="FavoritesFirst" value="true" />
    <bool name="ParseGamelistOnly" value="false" />
    <bool name="LocalArt" value="false" />
    
    <!-- Input Settings -->
    <bool name="BackgroundJoystickInput" value="false" />
</es_settings>
EOF

    # Create input configuration for common controllers
    mkdir -p "$RETROPIE_CONFIG_DIR/inputconfigs"
    
    # Xbox controller configuration
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Xbox Wireless Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Xbox Wireless Controller" deviceGUID="030000005e040000e002000000007200">
    <input name="a" type="button" id="0" value="1" />
    <input name="b" type="button" id="1" value="1" />
    <input name="x" type="button" id="2" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="4" value="1" />
    <input name="guide" type="button" id="5" value="1" />
    <input name="start" type="button" id="6" value="1" />
    <input name="leftstick" type="button" id="7" value="1" />
    <input name="rightstick" type="button" id="8" value="1" />
    <input name="leftshoulder" type="button" id="9" value="1" />
    <input name="rightshoulder" type="button" id="10" value="1" />
    <input name="dpup" type="button" id="11" value="1" />
    <input name="dpdown" type="button" id="12" value="1" />
    <input name="dpleft" type="button" id="13" value="1" />
    <input name="dpright" type="button" id="14" value="1" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF

    log_success "EmulationStation configuration optimized"
}

# Function to create ROM directories with sample content
create_rom_structure() {
    log_info "Creating ROM directory structure in $RETROPIE_ROMS_DIR..."
    
    # Create the main ROMs directory
    mkdir -p "$RETROPIE_ROMS_DIR"
    
    # ROM directory mapping: folder_name:display_name:description
    declare -A rom_systems=(
        # Nintendo Systems
        ["nes"]="Nintendo Entertainment System:8-bit Nintendo console (1985)"
        ["snes"]="Super Nintendo Entertainment System:16-bit Nintendo console (1990)"
        ["n64"]="Nintendo 64:64-bit Nintendo console (1996)"
        ["gb"]="Game Boy:Portable Nintendo console (1989)"
        ["gbc"]="Game Boy Color:Color portable Nintendo console (1998)"
        ["gba"]="Game Boy Advance:32-bit portable Nintendo console (2001)"
        ["nds"]="Nintendo DS:Dual-screen portable console (2004)"
        ["virtualboy"]="Virtual Boy:Nintendo's 3D portable console (1995)"
        ["gameandwatch"]="Game & Watch:Nintendo handheld games (1980-1991)"
        ["pokemini"]="Pokemon Mini:Nintendo's smallest handheld (2001)"
        
        # Sega Systems
        ["mastersystem"]="Sega Master System:8-bit Sega console (1986)"
        ["genesis"]="Sega Genesis/Mega Drive:16-bit Sega console (1988)"
        ["megadrive"]="Sega Mega Drive:16-bit Sega console (PAL regions)"
        ["sega32x"]="Sega 32X:Genesis/Mega Drive add-on (1994)"
        ["segacd"]="Sega CD:Genesis/Mega Drive CD add-on (1991)"
        ["saturn"]="Sega Saturn:32-bit Sega console (1994)"
        ["dreamcast"]="Sega Dreamcast:128-bit Sega console (1998)"
        ["gamegear"]="Sega Game Gear:Portable Sega console (1990)"
        ["sg-1000"]="SG-1000:Sega's first home console (1983)"
        
        # Sony Systems
        ["psx"]="Sony PlayStation:32-bit Sony console (1994)"
        ["psp"]="PlayStation Portable:Sony handheld console (2004)"
        
        # Atari Systems
        ["atari2600"]="Atari 2600:Classic Atari console (1977)"
        ["atari5200"]="Atari 5200:Advanced Atari console (1982)"
        ["atari7800"]="Atari 7800:Backward-compatible Atari console (1986)"
        ["atarilynx"]="Atari Lynx:Color handheld console (1989)"
        ["atarist"]="Atari ST:16-bit Atari computer (1985)"
        ["atarijaguar"]="Atari Jaguar:64-bit Atari console (1993)"
        ["atarijaguarcd"]="Atari Jaguar CD:CD add-on for Jaguar (1995)"
        ["atarixegs"]="Atari XEGS:8-bit Atari game system (1987)"
        
        # Arcade Systems
        ["arcade"]="Arcade:Classic arcade games"
        ["mame-libretro"]="MAME (libretro):Multiple Arcade Machine Emulator"
        ["mame-advmame"]="MAME (AdvanceMAME):Advanced MAME emulator"
        ["mame-mame4all"]="MAME (MAME4All):Optimized MAME for ARM"
        ["fba"]="Final Burn Alpha:Arcade emulator for various systems"
        ["neogeo"]="Neo Geo:SNK's arcade/home system (1990)"
        ["naomi"]="Sega Naomi:Dreamcast-based arcade system"
        
        # Computer Systems
        ["amiga"]="Commodore Amiga:16/32-bit computer series (1985)"
        ["c64"]="Commodore 64:8-bit home computer (1982)"
        ["amstradcpc"]="Amstrad CPC:8-bit computer series (1984)"
        ["apple2"]="Apple II:8-bit computer series (1977)"
        ["msx"]="MSX:8-bit computer standard (1983)"
        ["zxspectrum"]="ZX Spectrum:8-bit British computer (1982)"
        ["oric"]="Oric:8-bit computer series (1983)"
        ["pc88"]="NEC PC-88:8-bit Japanese computer"
        ["pc98"]="NEC PC-98:16-bit Japanese computer"
        ["x68000"]="Sharp X68000:16/32-bit Japanese computer"
        ["macintosh"]="Classic Macintosh:Apple's GUI computer (1984)"
        ["archimedes"]="Acorn Archimedes:32-bit RISC computer (1987)"
        
        # Other Consoles
        ["3do"]="3DO Interactive Multiplayer:32-bit console (1993)"
        ["coleco"]="ColecoVision:Second-generation console (1982)"
        ["intellivision"]="Intellivision:16-bit console (1979)"
        ["odyssey2"]="Magnavox Odyssey 2:Early home console (1978)"
        ["vectrex"]="Vectrex:Vector graphics console (1982)"
        ["channelf"]="Fairchild Channel F:Early cartridge console (1976)"
        ["astrocde"]="Bally Astrocade:Home console (1977)"
        ["gx4000"]="Amstrad GX4000:8-bit console (1990)"
        
        # Handheld Systems
        ["wonderswan"]="WonderSwan:Bandai handheld (1999)"
        ["wonderswancolor"]="WonderSwan Color:Color Bandai handheld (2000)"
        ["ngp"]="Neo Geo Pocket:SNK handheld (1998)"
        ["ngpc"]="Neo Geo Pocket Color:SNK color handheld (1999)"
        
        # PC Engine / TurboGrafx
        ["pcengine"]="PC Engine/TurboGrafx-16:16-bit console (1987)"
        ["pcfx"]="PC-FX:32-bit NEC console (1994)"
        
        # Other Systems
        ["fds"]="Famicom Disk System:Nintendo disk add-on (1986)"
        ["samcoupe"]="SAM Coupé:8-bit computer (1989)"
        ["ti99"]="TI-99/4A:Texas Instruments computer (1981)"
        ["trs-80"]="TRS-80:Tandy Radio Shack computer (1977)"
        ["coco"]="TRS-80 Color Computer:Tandy computer series"
        ["dragon32"]="Dragon 32:Welsh 8-bit computer (1982)"
        ["uzebox"]="Uzebox:Open source console"
        ["videopac"]="Philips Videopac G7000:European Odyssey 2"
        ["moto"]="Thomson MO/TO:French 8-bit computers"
        
        # Special Categories
        ["ports"]="Ports:Native Linux game ports"
        ["kodi"]="Kodi:Media center (optional EmulationStation feature)"
        ["scummvm"]="ScummVM:Adventure game engine"
        ["love"]="LÖVE:2D game engine"
        ["openbor"]="OpenBOR:Beat 'em up game engine"
        ["zmachine"]="Z-Machine:Interactive fiction engine"
        ["pc"]="PC:DOS and Windows games"
    )
    
    # Create directories with proper naming
    for system_key in "${!rom_systems[@]}"; do
        local system_info="${rom_systems[$system_key]}"
        local display_name="${system_info%%:*}"
        local description="${system_info#*:}"
        
        mkdir -p "$RETROPIE_ROMS_DIR/$system_key"
        
        # Create detailed README for each system
        cat > "$RETROPIE_ROMS_DIR/$system_key/README.txt" << EOF
=== $display_name ===
System: $system_key
Description: $description

PLACE YOUR ROM FILES HERE
========================

This directory is for $display_name ROM files.
Folder name: $system_key (use this exact name in EmulationStation)

Common file formats for this system:
$(case $system_key in
    "nes"|"fds") echo "• .nes, .zip" ;;
    "snes") echo "• .smc, .sfc, .zip" ;;
    "n64") echo "• .n64, .z64, .v64, .zip" ;;
    "gb"|"gbc") echo "• .gb, .gbc, .zip" ;;
    "gba") echo "• .gba, .zip" ;;
    "genesis"|"megadrive") echo "• .md, .gen, .bin, .zip" ;;
    "mastersystem") echo "• .sms, .zip" ;;
    "gamegear") echo "• .gg, .zip" ;;
    "psx") echo "• .cue/.bin, .iso, .pbp" ;;
    "atari2600") echo "• .a26, .bin, .zip" ;;
    "arcade"|"mame"*|"fba"|"neogeo") echo "• .zip (MAME ROM sets)" ;;
    "scummvm") echo "• Place game directories here" ;;
    "ports") echo "• .sh (shell scripts for native games)" ;;
    "kodi") echo "• Kodi is launched as a port" ;;
    *) echo "• Check RetroPie documentation for supported formats" ;;
esac)

IMPORTANT NOTES:
• Only use ROM files that you legally own
• Some systems require BIOS files in ~/RetroPie/BIOS/
• For MAME games, use the correct ROM set version
• Compressed files (.zip, .7z) are supported for most systems

For more information, visit: https://retropie.org.uk/docs/
EOF
        
    done
    
    # Create a main README in the ROMs directory
    cat > "$RETROPIE_ROMS_DIR/README.txt" << EOF
=== RETROPIE ROM COLLECTION ===

This directory contains subdirectories for each gaming system supported by RetroPie.
Each subdirectory is named with the exact system identifier used by EmulationStation.

QUICK START:
1. Navigate to the system folder you want (e.g., 'nes' for Nintendo Entertainment System)
2. Place your legally-owned ROM files in that folder
3. Restart EmulationStation to see your games

IMPORTANT:
• Use only ROM files that you legally own
• Some systems require BIOS files - place them in ~/RetroPie/BIOS/
• Folder names are case-sensitive and must match exactly

POPULAR SYSTEMS:
• nes - Nintendo Entertainment System
• snes - Super Nintendo Entertainment System  
• genesis - Sega Genesis/Mega Drive
• n64 - Nintendo 64
• psx - Sony PlayStation
• gba - Game Boy Advance
• arcade - Arcade games (MAME)

For complete documentation: https://retropie.org.uk/docs/
EOF
    
    # Create BIOS directory structure
    mkdir -p "$HOME/RetroPie/BIOS"
    cat > "$HOME/RetroPie/BIOS/README.txt" << EOF
=== BIOS FILES DIRECTORY ===

Some emulators require BIOS files to function properly.
Place BIOS files directly in this directory (not in subdirectories).

SYSTEMS THAT REQUIRE BIOS:
• PlayStation (psx): scph1001.bin, scph5501.bin, scph7001.bin
• Sega CD: bios_CD_E.bin, bios_CD_U.bin, bios_CD_J.bin  
• Sega Saturn: saturn_bios.bin
• PC Engine CD: syscard3.pce
• Neo Geo: neogeo.zip (BIOS ROM set)
• Dreamcast: dc_boot.bin, dc_flash.bin

IMPORTANT:
• BIOS files must be legally obtained
• File names are case-sensitive
• Some BIOS files have specific naming requirements
• Check RetroPie documentation for exact requirements

For BIOS setup guide: https://retropie.org.uk/docs/BIOS-Configuration/
EOF
    
    log_success "ROM directory structure created in $RETROPIE_ROMS_DIR"
    log_info "ROMs are now organized alongside your Documents, Downloads, etc."
}

# Function to install additional themes
install_themes() {
    log_info "Installing additional EmulationStation themes..."
    
    local theme_dir="$RETROPIE_CONFIG_DIR/themes"
    mkdir -p "$theme_dir"
    
    # List of popular themes to install
    local themes=(
        "https://github.com/RetroPie/es-theme-carbon.git:carbon"
        "https://github.com/RetroPie/es-theme-simple.git:simple"
        "https://github.com/RetroPie/es-theme-clean-look.git:clean-look"
        "https://github.com/lilbud/es-theme-switchOS.git:switchOS"
        "https://github.com/RetroPie/es-theme-pixel.git:pixel"
    )
    
    for theme_info in "${themes[@]}"; do
        local theme_url="${theme_info%%:*}"
        local theme_name="${theme_info#*:}"
        
        if [ ! -d "$theme_dir/$theme_name" ]; then
            log_info "Installing theme: $theme_name"
            if git clone --depth=1 "$theme_url" "$theme_dir/$theme_name"; then
                log_success "Theme $theme_name installed"
            else
                log_warn "Failed to install theme $theme_name"
            fi
        else
            log_info "Theme $theme_name already exists, skipping"
        fi
    done
}

# Function to create autostart script for EmulationStation
configure_autostart() {
    log_info "Configuring EmulationStation autostart..."
    
    # Create autostart script in user directory
    cat > "$HOME/.bashrc_emulationstation" << 'EOF'
# EmulationStation autostart configuration
# This will start EmulationStation on login for TTY1

if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ "$USER" != "root" ]; then
    echo "Starting EmulationStation..."
    emulationstation
fi
EOF

    # Add to .bashrc if not already present
    if ! grep -q ".bashrc_emulationstation" "$HOME/.bashrc" 2>/dev/null; then
        echo "source ~/.bashrc_emulationstation" >> "$HOME/.bashrc"
        log_success "EmulationStation autostart configured"
    else
        log_info "EmulationStation autostart already configured"
    fi
}

# Function to apply Raspberry Pi specific optimizations
apply_pi_optimizations() {
    log_info "Applying Raspberry Pi specific optimizations..."
    
    # Check if this is a Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        log_info "Not a Raspberry Pi, skipping Pi-specific optimizations"
        return 0
    fi
    
    # GPU memory split optimization
    log_info "Optimizing GPU memory split..."
    if grep -q "gpu_mem" /boot/config.txt 2>/dev/null; then
        sudo sed -i 's/gpu_mem=.*/gpu_mem=128/' /boot/config.txt
    else
        echo "gpu_mem=128" | sudo tee -a /boot/config.txt >/dev/null
    fi
    
    # Enable necessary overlays for emulation
    local overlays=(
        "dtoverlay=vc4-kms-v3d"
        "dtparam=audio=on"
        "dtoverlay=dwc2"
    )
    
    for overlay in "${overlays[@]}"; do
        if ! grep -q "$overlay" /boot/config.txt 2>/dev/null; then
            echo "$overlay" | sudo tee -a /boot/config.txt >/dev/null
            log_info "Added overlay: $overlay"
        fi
    done
    
    # Optimize for performance
    local performance_settings=(
        "arm_freq=2100"
        "over_voltage=2"
        "temp_limit=80"
        "initial_turbo=60"
    )
    
    for setting in "${performance_settings[@]}"; do
        local key="${setting%%=*}"
        if ! grep -q "$key" /boot/config.txt 2>/dev/null; then
            echo "$setting" | sudo tee -a /boot/config.txt >/dev/null
            log_info "Added performance setting: $setting"
        fi
    done
    
    log_success "Raspberry Pi optimizations applied"
}

# Function to create helpful scripts and utilities
create_utilities() {
    log_info "Creating utility scripts..."
    
    # Create a script to easily switch between Kodi and EmulationStation
    cat > "$HOME/switch-to-kodi.sh" << 'EOF'
#!/bin/bash
# Quick switch to Kodi from EmulationStation

echo "Switching to Kodi..."
pkill -f emulationstation
sleep 2
kodi-standalone
echo "Kodi exited, restarting EmulationStation..."
emulationstation &
EOF

    chmod +x "$HOME/switch-to-kodi.sh"
    
    # Create a script to restart EmulationStation
    cat > "$HOME/restart-es.sh" << 'EOF'
#!/bin/bash
# Restart EmulationStation

echo "Restarting EmulationStation..."
pkill -f emulationstation
sleep 2
emulationstation &
echo "EmulationStation restarted"
EOF

    chmod +x "$HOME/restart-es.sh"
    
    # Create a system info script for debugging
    cat > "$HOME/system-info.sh" << 'EOF'
#!/bin/bash
# Display system information useful for troubleshooting

echo "=== System Information ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Temperature: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"
echo "Throttling: $(vcgencmd get_throttled 2>/dev/null || echo 'N/A')"
echo ""

echo "=== EmulationStation Status ==="
if pgrep -f emulationstation > /dev/null; then
    echo "EmulationStation: Running"
else
    echo "EmulationStation: Not running"
fi

echo ""
echo "=== Kodi Status ==="
if pgrep -f kodi > /dev/null; then
    echo "Kodi: Running"
else
    echo "Kodi: Not running"
fi

echo ""
echo "=== Storage ==="
df -h | grep -E "(Filesystem|/dev/)"
EOF

    chmod +x "$HOME/system-info.sh"
    
    # Create controller management script
    cat > "$HOME/controller-setup.sh" << 'EOF'
#!/bin/bash
# Controller Setup and Management Script

echo "=== Controller Setup and Management ==="
echo "1. Scan for controllers"
echo "2. Pair new controller" 
echo "3. List paired controllers"
echo "4. Test controller input"
echo "5. Remove paired controller"
echo "6. Controller discovery report"
echo ""

read -p "Choose option (1-6): " choice

case $choice in
    1)
        echo "Scanning for controllers..."
        /usr/local/bin/controller-discovery.py
        ;;
    2)
        echo "Put your controller in pairing mode and press Enter..."
        read
        /usr/local/bin/controller-autopair.py
        ;;
    3)
        echo "Paired Bluetooth controllers:"
        bluetoothctl devices | grep -E "(Controller|Xbox|PlayStation|Nintendo|8BitDo)"
        echo ""
        echo "USB Controllers:"
        lsusb | grep -E "(Xbox|PlayStation|Nintendo|Logitech|Controller)"
        ;;
    4)
        echo "Available joystick devices:"
        ls /dev/input/js* 2>/dev/null || echo "No joystick devices found"
        echo ""
        echo "Choose a device to test (e.g., /dev/input/js0):"
        read device
        if [ -e "$device" ]; then
            echo "Testing $device (press Ctrl+C to stop):"
            jstest "$device"
        else
            echo "Device not found"
        fi
        ;;
    5)
        echo "Paired devices:"
        bluetoothctl devices
        echo ""
        read -p "Enter MAC address to remove: " mac
        if [ -n "$mac" ]; then
            bluetoothctl remove "$mac"
        fi
        ;;
    6)
        echo "Generating controller discovery report..."
        /usr/local/bin/controller-discovery.py
        cat /home/pi/RetroPie/controller_reports/latest.json
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF

    chmod +x "$HOME/controller-setup.sh"
    
    # Create quick pairing script
    cat > "$HOME/pair-controller.sh" << 'EOF'
#!/bin/bash
# Quick Controller Pairing Script

echo "=== Quick Controller Pairing ==="
echo "Put your controller in pairing mode:"
echo "• Xbox: Hold pairing button until blinking"
echo "• PlayStation: Hold Share + PS buttons"
echo "• Nintendo Switch Pro: Hold pairing button"
echo "• 8BitDo: Hold pairing button"
echo ""
echo "Press Enter when ready..."
read

/usr/local/bin/controller-autopair.py
EOF

    chmod +x "$HOME/pair-controller.sh"
    
    log_success "Utility scripts created"
}

# Function to display installation summary
display_summary() {
    log_info "EmulationStation + automatic controller setup completed for user $USER!"
    echo ""
    echo "=== Installation Summary ==="
    echo "✓ RetroPie/EmulationStation installed for user $USER with all major emulators"
    echo "✓ Automatic controller support with discovery and pairing"
    echo "✓ Kodi integration available (run separate setup if desired)"
    echo "✓ System optimizations applied"
    echo "✓ ROM directories created in ~/ROMs/ (alongside Documents, Downloads, etc.)"
    echo "✓ Pre-configured controller mappings for major brands"
    echo "✓ Utility scripts created"
    echo ""
    echo "=== Next Steps ==="
    echo "1. EmulationStation is ready to use (no reboot required for software)"
    echo "2. If hardware changes were made (./start.sh), reboot to activate them"
    echo "3. On first boot, EmulationStation will start automatically for user $USER"
    echo "4. Controllers will be detected and configured automatically"
    echo "5. Add ROM files to ~/ROMs/<system>/ (proper platform folders created)"
    echo "6. Optional: Run ./setup_kodi.sh for Kodi integration"
    echo ""
    echo "=== Useful Commands ==="
    echo "• Start EmulationStation: emulationstation"
    echo "• Pair controller: ~/pair-controller.sh"
    echo "• Controller management: ~/controller-setup.sh"
    echo "• System information: ~/system-info.sh"
    echo "• RetroPie setup menu: cd ~/RetroPie-Setup && sudo ./retropie_setup.sh"
    echo "• Kodi setup: cd ${SCRIPT_DIR} && ./setup_kodi.sh"
    echo ""
    echo "=== ROM Directories ==="
    echo "ROMs are located in: ~/ROMs/<system>/ (alongside your Documents, Downloads, etc.)"
    echo "Each folder has detailed README with supported file formats"
    echo "Popular systems: nes, snes, genesis, n64, psx, gba, arcade"
    echo "Remember: Only use ROMs that you legally own!"
    echo ""
    echo "=== Controller Support ==="
    echo "• Automatic detection for USB, Bluetooth, and wireless controllers"
    echo "• Pre-configured for Xbox, PlayStation, Nintendo Switch, 8BitDo controllers"
    echo "• Background auto-pairing service enabled"
    echo "• Use ~/pair-controller.sh for quick pairing of new controllers"
    echo ""
    log_success "EmulationStation setup complete! Software is ready to use."
    log_info "If you ran ./start.sh first, reboot when all installations are finished to activate hardware optimizations."
}

# Main execution function
main() {
    log_info "=== EmulationStation with Automatic Controller Support ==="
    echo "This script will install for user $USER:"
    echo "• RetroPie/EmulationStation with all major emulators"
    echo "• Experimental emulators and features"  
    echo "• Automatic controller discovery, pairing, and mapping"
    echo "• ROM directories in ~/ROMs/ with proper platform names"
    echo "• System optimizations for best performance"
    echo "• Optional Kodi integration (separate script available)"
    echo ""
    
    # Confirmation prompt
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Execute installation steps
    check_hardware
    install_dependencies
    install_controller_dependencies
    setup_retropie
    install_retropie_packages
    install_emulators
    configure_controller_support
    configure_kodi_integration
    optimize_emulationstation
    create_rom_structure
    install_themes
    configure_autostart
    apply_pi_optimizations
    create_utilities
    
    # Display completion summary
    display_summary
}

# Execute main function
main "$@"
