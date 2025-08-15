#!/bin/bash

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/../utils/common.sh"

install_required_packages() {
    echo "Installing necessary packages for Home Assistant..."
    
    apt-get update -qq
    
    apt-get install -y \
        jq \
        wget \
        curl \
        avahi-daemon \
        udisks2 \
        libglib2.0-bin \
        apparmor \
        apparmor-utils \
        ca-certificates \
        cifs-utils \
        dbus \
        systemd-journal-remote \
        systemd-resolved
    
    echo "✓ Required packages installed"
    
    # Configure NetworkManager
    # DISABLED: This breaks internet connectivity
    # if [[ -f "/etc/NetworkManager/NetworkManager.conf" ]]; then
    #     sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
    #     echo "✓ NetworkManager configured"
    # fi
    echo "⚠ NetworkManager config SKIPPED to preserve internet connectivity"
}

install_docker() {
    echo "Installing Docker..."
    
    if command -v docker >/dev/null 2>&1; then
        echo "Docker already installed"
        docker --version
        return 0
    fi
    
    echo "Running Docker installer..."
    curl -fsSL get.docker.com | sh
    
    if command -v docker >/dev/null 2>&1; then
        echo "✓ Docker installed successfully"
        docker --version
        
        if [[ -n "${SUDO_USER:-}" ]]; then
            usermod -aG docker "$SUDO_USER"
            echo "✓ Added $SUDO_USER to docker group"
        fi
    else
        echo "ERROR: Docker installation failed"
        exit 1
    fi
}

install_os_agent() {
    echo "Installing Home Assistant OS Agent..."
    
    local agent_url="https://github.com/home-assistant/os-agent/releases/latest/download/os-agent_1.6.0_linux_aarch64.deb"
    local agent_file="/tmp/os-agent_1.6.0_linux_aarch64.deb"
    
    wget -O "$agent_file" "$agent_url"
    dpkg -i "$agent_file"
    
    echo "Verifying OS Agent installation..."
    if gdbus introspect --system --dest io.hass.os --object-path /io/hass/os >/dev/null 2>&1; then
        echo "✓ OS Agent installed and verified"
    else
        echo "ERROR: OS Agent verification failed"
        exit 1
    fi
    
    rm -f "$agent_file"
}

install_homeassistant_supervised() {
    echo "Installing Home Assistant Supervised..."
    
    wget -O homeassistant-supervised.deb \
        https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
    
    apt install ./homeassistant-supervised.deb
    
    echo "✓ Home Assistant Supervised installation completed"
    rm -f homeassistant-supervised.deb
}

verify_installation() {
    echo "Verifying Home Assistant installation..."
    
    local ip_address=$(hostname -I | awk '{print $1}')
    echo "Waiting for Home Assistant to start..."
    echo "This may take a few minutes..."
    
    local max_attempts=20
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -f "http://${ip_address}:8123" >/dev/null 2>&1; then
            echo ""
            echo "=================================================================="
            echo "  Home Assistant Supervised Successfully Installed!"
            echo "  "
            echo "  Access your Home Assistant at:"
            echo "  • http://${ip_address}:8123"
            echo "  • http://homeassistant.local:8123"
            echo "=================================================================="
            return 0
        fi
        
        ((attempt++))
        echo "Attempt $attempt/$max_attempts - Still waiting..."
        sleep 30
    done
    
    echo "WARNING: Home Assistant did not respond within 10 minutes"
    echo "Try accessing http://${ip_address}:8123 in a few more minutes"
}

main() {
    echo "=================================================================="
    echo "  Home Assistant Supervised Installation"
    echo "  Following Neil Turner's Proven Guide"
    echo "=================================================================="
    echo ""
    
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: This script must be run as root (use sudo)"
        exit 1
    fi
    
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        echo "WARNING: This script is optimized for Raspberry Pi"
        read -p "Continue anyway? (y/N): " -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo "Starting installation..."
    echo ""
    
    install_required_packages
    echo ""
    
    install_docker
    echo ""
    
    install_os_agent
    echo ""
    
    install_homeassistant_supervised
    echo ""
    
    verify_installation
    
    echo ""
    echo "Installation Complete!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
        jq \
        wget \
        curl \
        avahi-daemon \
        udisks2 \
        libglib2.0-bin \
        apparmor \
        apparmor-utils \
        ca-certificates \
        cifs-utils \
        dbus \
        network-manager \
        systemd-journal-remote \
        systemd-resolved
    
    echo "✓ All required packages installed successfully"
    
    # Configure NetworkManager as mentioned in the guide - DISABLED
    echo "→ Configuring NetworkManager..."
    # CRITICAL: Do NOT change NetworkManager settings - it breaks internet!
    # if [[ -f "/etc/NetworkManager/NetworkManager.conf" ]]; then
    #     # Change managed=false to true as mentioned in the guide
    #     sed -i 's/managed=false/managed=true/g' /etc/NetworkManager/NetworkManager.conf
    #     echo "✓ NetworkManager configured (managed=true)"
    # else
    #     echo "⚠ NetworkManager config not found - may not be needed"
    # fi
    echo "⚠ NetworkManager config changes DISABLED to preserve internet connectivity"
}

###############################################################################
# Step 2: Install Docker (exact command from Neil Turner's guide)
###############################################################################

install_docker() {
    echo " === Step 2: Installing Docker ==="
    
    # Check if Docker is already installed
    if command -v docker >/dev/null 2>&1; then
        echo " Docker is already installed"
        docker --version
        return 0
    fi
    
    # Install Docker using the EXACT command from Neil Turner's guide
    echo " Installing Docker using official installer..."
    echo " Running: curl -fsSL get.docker.com | sh"
    
    curl -fsSL get.docker.com | sh
    
    # Verify Docker installation
    if command -v docker >/dev/null 2>&1; then
        echo " Docker installed successfully"
        docker --version
        
        # Add user to docker group
        if [[ -n "${SUDO_USER:-}" ]]; then
            usermod -aG docker "$SUDO_USER"
            echo " Added $SUDO_USER to docker group"
        fi
    else
        echo " Docker installation failed"
        exit 1
    fi
}

###############################################################################
# Step 3: Install OS Agent (from Neil Turner's guide)
###############################################################################

install_os_agent() {
    echo " === Step 3: Installing Home Assistant OS Agent ==="
    
    # Get the latest OS Agent version for aarch64 (Raspberry Pi)
    local agent_url="https://github.com/home-assistant/os-agent/releases/latest/download/os-agent_1.6.0_linux_aarch64.deb"
    local agent_file="/tmp/os-agent_1.6.0_linux_aarch64.deb"
    
    echo " Downloading OS Agent..."
    wget -O "$agent_file" "$agent_url"
    
    echo " Installing OS Agent..."
    dpkg -i "$agent_file"
    
    # Verify installation using the EXACT command from Neil Turner's guide
    echo " Verifying OS Agent installation..."
    if gdbus introspect --system --dest io.hass.os --object-path /io/hass/os >/dev/null 2>&1; then
        echo " OS Agent installed and verified successfully"
    else
        echo " OS Agent verification failed"
        echo " If you get 'gdbus command not found', you may have missed libglib2.0-bin package"
        exit 1
    fi
    
    # Clean up
    rm -f "$agent_file"
}

###############################################################################
# Step 4: Install Home Assistant Supervised (from Neil Turner's guide)
###############################################################################

install_homeassistant_supervised() {
    echo " === Step 4: Installing Home Assistant Supervised ==="
    
    # Download Home Assistant Supervised using EXACT commands from guide
    echo " Downloading Home Assistant Supervised installer..."
    
    wget -O homeassistant-supervised.deb \
        https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
    
    echo " Installing Home Assistant Supervised..."
    apt install ./homeassistant-supervised.deb
    
    echo " Home Assistant Supervised installation completed"
    
    # Clean up
    rm -f homeassistant-supervised.deb
}

###############################################################################
# Step 5: Verify and wait for Home Assistant (from Neil Turner's guide)
###############################################################################

verify_installation() {
    echo " === Step 5: Verifying Home Assistant installation ==="
    
    local ip_address=$(hostname -I | awk '{print $1}')
    echo " Waiting for Home Assistant to start..."
    echo " This may take a few minutes as containers are downloaded and started..."
    
    # Wait up to 10 minutes for Home Assistant to be ready
    local max_attempts=20
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -f "http://${ip_address}:8123" >/dev/null 2>&1; then
            echo " Home Assistant is accessible!"
            echo ""
            echo "=================================================================="
            echo "  🎉 HOME ASSISTANT SUPERVISED SUCCESSFULLY INSTALLED!"
            echo "  "
            echo "  Access your Home Assistant at:"
            echo "  • http://${ip_address}:8123"
            echo "  • http://homeassistant.local:8123"
            echo "  "
            echo "  Complete the onboarding process in your web browser."
            echo "  You may restore a backup if migrating from another system."
            echo "=================================================================="
            return 0
        fi
        
        ((attempt++))
        echo " Attempt $attempt/$max_attempts - Still waiting for Home Assistant to start..."
        sleep 30
    done
    
    echo " Home Assistant did not respond within 10 minutes"
    echo " This doesn't necessarily mean installation failed - containers may still be starting"
    echo " Try accessing http://${ip_address}:8123 in a few more minutes"
}

###############################################################################
# Main installation function
###############################################################################

main() {
    echo "=================================================================="
    echo "  Home Assistant Supervised Installation"
    echo "  Following Neil Turner's Proven Guide"
    echo "=================================================================="
    echo ""
    echo "This script follows the exact process from:"
    echo "https://neilturner.me.uk/2024/01/10/how-to-install-home-assistant-supervised-on-a-raspberry-pi/"
    echo ""
    echo "Steps to be performed:"
    echo "1. Install necessary packages"
    echo "2. Install Docker"
    echo "3. Install Home Assistant OS Agent"
    echo "4. Install Home Assistant Supervised"
    echo "5. Verify installation"
    echo ""
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo " This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check if running on Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        echo " This script is optimized for Raspberry Pi"
        echo "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo "Starting installation..."
    echo ""
    
    # Execute the 5 steps from Neil Turner's guide
    install_required_packages
    echo ""
    
    install_docker
    echo ""
    
    install_os_agent
    echo ""
    
    install_homeassistant_supervised
    echo ""
    
    verify_installation
    
    echo ""
    echo "=================================================================="
    echo "  Installation Complete!"
    echo "  "
    echo "  Next steps:"
    echo "  1. Access Home Assistant at http://[your-pi-ip]:8123"
    echo "  2. Complete the onboarding process"
    echo "  3. Install add-ons from the Supervisor panel"
    echo "  4. Configure your smart home devices"
    echo "=================================================================="
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
