#!/bin/bash

###############################################################################
# Dependencies Installation Script
# 
# This script handles system updates and package installation
# Part of the modular RaspiCommandCenter setup
#
# Author: RaspiCommandCenter
# Version: 1.0.0
###############################################################################

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

###############################################################################
# System Update Functions
###############################################################################

update_system() {
    log_info "Updating package lists (SAFE - no system upgrades)..."
    
    # Update package lists ONLY - this is safe
    apt update
    
    # DO NOT UPGRADE PACKAGES - this breaks drivers and firmware!
    # DEBIAN_FRONTEND=noninteractive apt upgrade -y  # REMOVED - DANGEROUS!
    log_warn "Skipping 'apt upgrade' to prevent driver/firmware breakage"
    log_info "Your system drivers and firmware will remain stable"
    
    # Clean up package cache only
    apt autoclean
    
    log_success "SAFE package list update completed (no system changes)"
}

###############################################################################
# Package Installation Functions
###############################################################################

install_essential_packages() {
    log_info "Installing essential system packages..."
    
    local packages=(
        # Build essentials
        "build-essential"
        "git"
        "curl"
        "wget"
        "unzip"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        
        # System utilities
        "htop"
        "tree"
        "nano"
        "vim"
        "rsync"
        "screen"
        "tmux"
        
        # Hardware support
        "i2c-tools"
        "python3-smbus"
        "python3-pip"
        "python3-setuptools"
        "python3-dev"
        
        # Network utilities (safe - no NetworkManager conflicts)
        "avahi-daemon"
        "avahi-utils"
        
        # Media and codec support
        "ffmpeg"
        "libavcodec-extra"
        
        # Development tools
        "cmake"
        "pkg-config"
        "autoconf"
        "automake"
        "libtool"
    )
    
    # Install packages with error handling
    for package in "${packages[@]}"; do
        if apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package (continuing...)"
        fi
    done
    
    log_success "Essential packages installation completed"
}

install_raspberry_pi_packages() {
    log_info "Installing Raspberry Pi specific packages..."
    
    local pi_packages=(
        # Raspberry Pi tools (SAFE SUBSET - no dangerous firmware tools)
        "raspi-config"
        # "rpi-update"          # REMOVED - DANGEROUS! Can break firmware
        # "rpi-eeprom"          # REMOVED - Can break boot process
        "libraspberrypi-bin"
        "libraspberrypi-dev"
        
        # GPIO and hardware interfaces
        "wiringpi"
        "python3-rpi.gpio"
        "python3-gpiozero"
        
        # Camera support
        "python3-picamera"
        "python3-picamera2"
        
        # Video acceleration
        "libgl1-mesa-dri"
        "mesa-utils"
        "mesa-utils-extra"
    )
    
    # Install Pi-specific packages
    for package in "${pi_packages[@]}"; do
        if apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package (continuing...)"
        fi
    done
    
    log_success "Raspberry Pi packages installation completed"
}

install_media_packages() {
    log_info "Installing media and entertainment packages..."
    
    local media_packages=(
        # Kodi and media center
        "kodi"
        "kodi-peripheral-joystick"
        "kodi-inputstream-adaptive"
        "kodi-inputstream-rtmp"
        
        # Audio support
        "alsa-utils"
        "pulseaudio"
        "pulseaudio-utils"
        "pavucontrol"
        
        # Video libraries
        "libavformat-dev"
        "libavcodec-dev"
        "libavdevice-dev"
        "libavfilter-dev"
        "libavutil-dev"
        "libswscale-dev"
        "libswresample-dev"
        
        # Image processing
        "libjpeg-dev"
        "libpng-dev"
        "libtiff-dev"
        "libwebp-dev"
    )
    
    # Install media packages
    for package in "${media_packages[@]}"; do
        if apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package (continuing...)"
        fi
    done
    
    log_success "Media packages installation completed"
}

install_gaming_packages() {
    log_info "Installing gaming and emulation packages..."
    
    local gaming_packages=(
        # Gaming libraries
        "libsdl2-dev"
        "libsdl2-image-dev"
        "libsdl2-mixer-dev"
        "libsdl2-ttf-dev"
        "libsdl2-gfx-dev"
        
        # Controller support
        "joystick"
        "jstest-gtk"
        "bluetooth"
        "bluez"
        "bluez-tools"
        
        # Emulation dependencies
        "libretro-core-info"
        "retroarch"
        "retroarch-assets"
        "libretro-beetle-psx"
        "libretro-snes9x"
        "libretro-genesis-plus-gx"
        
        # Development libraries for compilation
        "libboost-all-dev"
        "libeigen3-dev"
        "libfreeimage-dev"
        "libfreetype6-dev"
        "libcurl4-openssl-dev"
        "rapidjson-dev"
        "libvlc-dev"
        "libfftw3-dev"
    )
    
    # Install gaming packages
    for package in "${gaming_packages[@]}"; do
        if apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package (continuing...)"
        fi
    done
    
    log_success "Gaming packages installation completed"
}

install_docker() {
    log_info "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        log_info "Docker already installed, skipping..."
        return 0
    fi
    
    # Install Docker using official script
    log_info "Downloading Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    
    log_info "Running Docker installation..."
    sh get-docker.sh
    
    # Clean up
    rm get-docker.sh
    
    # Add current user to docker group (if not root)
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        log_info "Added $SUDO_USER to docker group"
    fi
    
    # Enable Docker service
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker installed and configured successfully"
}

install_home_assistant_dependencies() {
    log_info "Installing Home Assistant dependencies..."
    
    local ha_packages=(
        # Core dependencies for Home Assistant Supervised
        "jq"
        "wget"
        "curl"
        "avahi-daemon"
        "dbus"
        # "network-manager"  # REMOVED - causes network conflicts
        "apparmor"
        "apparmor-utils"
        "udisks2"
        "libglib2.0-bin"
        
        # Additional useful packages
        "systemd-journal-remote"
        "systemd-resolved"
    )
    
    # Install HA dependencies
    for package in "${ha_packages[@]}"; do
        if apt install -y "$package"; then
            log_info "✓ Installed: $package"
        else
            log_warn "✗ Failed to install: $package (continuing...)"
        fi
    done
    
    log_success "Home Assistant dependencies installation completed"
}

###############################################################################
# Firmware Updates
###############################################################################

disable_dangerous_firmware_updates() {
    log_warn "FIRMWARE UPDATES DISABLED FOR SYSTEM SAFETY"
    echo ""
    echo "⚠️  DANGEROUS OPERATIONS DISABLED:"
    echo "   • rpi-eeprom-update -a  (can break boot)"
    echo "   • rpi-update           (can break drivers/firmware)"
    echo "   • apt upgrade          (can break everything)"
    echo ""
    echo "✅ Your system will remain stable and functional"
    echo ""
    echo "If you absolutely need firmware updates later (NOT recommended):"
    echo "   • Manual EEPROM: sudo rpi-eeprom-config --edit"
    echo "   • Manual firmware: sudo rpi-update (DANGEROUS)"
    echo ""
    log_success "System safety ensured - no dangerous updates performed"
}

###############################################################################
# Main execution
###############################################################################

main() {
    log_info "=== Dependencies Installation Script (SAFE VERSION) ==="
    echo ""
    echo "This script will install required packages without performing dangerous system upgrades."
    
    # Execute SAFE installation steps
    update_system
    install_essential_packages
    install_raspberry_pi_packages
    install_media_packages
    install_gaming_packages
    install_docker
    install_home_assistant_dependencies
    
    log_success "=== SAFE Dependencies installation completed! ==="
    echo ""
    echo "✅ System remains stable - no dangerous upgrades or firmware changes were made."
    echo "Next step: Run configure_performance.sh for hardware optimization."
}# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
