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
    log_info "Updating system packages..."
    
    # Update package lists
    apt update
    
    # Upgrade existing packages (non-interactive)
    DEBIAN_FRONTEND=noninteractive apt upgrade -y
    
    # Clean up package cache
    apt autoremove -y
    apt autoclean
    
    log_success "System update completed"
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
        
        # Network utilities
        "network-manager"
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
        # Raspberry Pi tools
        "raspi-config"
        "rpi-update"
        "rpi-eeprom"
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
        "network-manager"
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

update_firmware() {
    log_info "Updating Raspberry Pi firmware..."
    
    # Ensure ca-certificates is installed for secure downloads
    if ! dpkg -l | grep -q "ca-certificates"; then
        log_info "Installing ca-certificates for secure downloads..."
        apt-get update
        apt-get install -y ca-certificates
    fi
    
    # Update bootloader firmware
    if [[ -d "/lib/firmware/raspberrypi/bootloader" ]]; then
        log_info "Updating bootloader firmware..."
        if rpi-eeprom-update -a; then
            log_success "Bootloader firmware updated"
        else
            log_warn "Bootloader update failed, but continuing..."
        fi
    else
        log_warn "Bootloader firmware directory not found"
    fi
    
    # Update kernel and firmware (optional, can be skipped if stable)
    read -p "Update kernel and firmware? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Updating kernel and firmware..."
        if rpi-update; then
            log_success "Kernel and firmware updated"
        else
            log_warn "Kernel/firmware update failed, but continuing..."
        fi
    else
        log_info "Skipping kernel/firmware update"
    fi
}

###############################################################################
# Main execution
###############################################################################

main() {
    log_info "=== Dependencies Installation Script ==="
    echo ""
    echo "This script will install:"
    echo "• System updates and essential packages"
    echo "• Raspberry Pi specific tools"
    echo "• Media and gaming libraries" 
    echo "• Docker containerization platform"
    echo "• Home Assistant dependencies"
    echo ""
    
    # Confirmation
    read -p "Continue with dependency installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Execute installation steps
    log_info "Starting dependency installation..."
    
    update_system
    install_essential_packages
    install_raspberry_pi_packages
    install_media_packages
    install_gaming_packages
    install_docker
    install_home_assistant_dependencies
    update_firmware
    
    log_success "=== Dependencies installation completed! ==="
    echo ""
    echo "Next step: Run configure_performance.sh to set up overclocking and performance settings"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
