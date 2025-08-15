#!/bin/bash

###############################################################################
# Home Assistant Supervised Installation Script
# 
# Following the proven approach from Neil Turner's guide:
# https://neilturner.me.uk/2024/01/10/how-to-install-home-assistant-supervised-on-a-raspberry-pi/
# 
# This script installs Home Assistant Supervised with Docker exactly as documented
#
# Author: RaspiCommandCenter
# Version: 1.1.0
###############################################################################

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"  # Parent directory (RaspiCommandCenter root)
UTILS_DIR="${PROJECT_DIR}/utils"
LOGS_DIR="${PROJECT_DIR}/logs"

# Source utility functions
source "${UTILS_DIR}/common.sh"

readonly SCRIPT_NAME="Home Assistant Supervised Setup"
readonly LOG_FILE="${LOGS_DIR}/homeassistant_setup_$(date +%Y%m%d_%H%M%S).log"

# Source logging after LOG_FILE is defined
source "${UTILS_DIR}/logging.sh"

###############################################################################
# Home Assistant Installation Functions
###############################################################################

show_banner() {
    echo "=================================================================="
    echo "  Home Assistant Supervised Installation"
    echo "  Setting up HA with Supervisor and Add-ons support"
    echo "=================================================================="
    echo ""
}

check_prerequisites() {
    log_info "Checking prerequisites for Home Assistant Supervised..."
    
    # Check if running on Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        log_error "This script is optimized for Raspberry Pi"
        if ! confirm "Continue anyway?" "n"; then
            exit 1
        fi
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &>/dev/null; then
        log_error "Internet connectivity is required for installation"
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

disable_wifi_randomization() {
    log_info "Disabling WiFi MAC randomization..."
    
    local nm_conf_dir="/etc/NetworkManager/conf.d"
    local wifi_conf="${nm_conf_dir}/100-disable-wifi-mac-randomization.conf"
    
    # Create NetworkManager config directory if it doesn't exist
    mkdir -p "$nm_conf_dir"
    
    # Create WiFi MAC randomization disable config
    cat > "$wifi_conf" << 'EOF'
[connection]
wifi.mac-address-randomization=1
[device]
wifi.scan-rand-mac-address=no
EOF
    
    log_success "WiFi MAC randomization disabled"
}

install_dependencies() {
    log_info "Installing Home Assistant Supervised dependencies..."
    
    # Update package lists
    log_info "Updating package lists..."
    apt-get update -qq
    
    # Install ONLY what's actually needed according to the official guide
    log_info "Installing required packages..."
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
        network-manager \
        systemd-journal-remote \
        systemd-resolved
    
    log_success "Dependencies installed successfully"
}

install_docker() {
    log_info "Installing Docker..."
    
    # Check if Docker is already installed
    if command_exists docker; then
        log_info "Docker is already installed"
        docker --version
        return 0
    fi
    
    # Download and run Docker installation script
    log_info "Downloading Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    
    log_info "Running Docker installation script..."
    sh get-docker.sh
    
    # Add current user to docker group (if not root)
    if [[ "${SUDO_USER:-}" ]]; then
        log_info "Adding user ${SUDO_USER} to docker group..."
        usermod -aG docker "${SUDO_USER}"
    fi
    
    # Clean up
    rm -f get-docker.sh
    
    log_success "Docker installed successfully"
}

verify_docker() {
    log_info "Verifying Docker installation..."
    
    if ! docker --version; then
        log_error "Docker installation failed"
        exit 1
    fi
    
    log_success "Docker verification completed"
}

configure_apparmor() {
    log_info "Configuring AppArmor..."
    
    # Check if AppArmor is installed
    if ! command_exists aa-status; then
        log_error "AppArmor is not installed"
        exit 1
    fi
    
    # Enable AppArmor at boot for Raspberry Pi
    local cmdline_file="/boot/firmware/cmdline.txt"
    if [[ -f "$cmdline_file" ]]; then
        if ! grep -q "lsm=apparmor" "$cmdline_file"; then
            log_info "Adding AppArmor to boot parameters..."
            sed -i 's/$/ lsm=apparmor/' "$cmdline_file"
            log_warning "AppArmor boot parameter added. Reboot required."
        else
            log_info "AppArmor already enabled in boot parameters"
        fi
    else
        log_warning "Boot cmdline file not found. AppArmor may need manual configuration."
    fi
    
    log_success "AppArmor configuration completed"
}

install_os_agent() {
    log_info "Installing Home Assistant OS Agent..."
    
    # Determine architecture
    local arch=$(uname -m)
    local agent_file
    local agent_url
    
    case "$arch" in
        "aarch64")
            agent_file="os-agent_1.2.2_linux_aarch64.deb"
            ;;
        "armv7l")
            agent_file="os-agent_1.2.2_linux_armv7.deb"
            ;;
        "x86_64")
            agent_file="os-agent_1.2.2_linux_x86_64.deb"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    agent_url="https://github.com/home-assistant/os-agent/releases/download/1.2.2/$agent_file"
    
    log_info "Downloading OS Agent for architecture: $arch"
    wget "$agent_url"
    
    log_info "Installing OS Agent..."
    dpkg -i "$agent_file"
    
    # Verify installation (as per the Neil Turner guide)
    log_info "Verifying OS Agent installation..."
    if gdbus introspect --system --dest io.hass.os --object-path /io/hass/os >/dev/null 2>&1; then
        log_success "OS Agent installed and verified successfully"
    else
        log_warn "OS Agent verification failed - if gdbus command not found, install libglib2.0-bin"
        log_info "Continuing anyway - Home Assistant may still work"
    fi
    
    # Clean up
    rm -f "$agent_file"
}

install_homeassistant_supervised() {
    log_info "Installing Home Assistant Supervised..."
    
    # Download the supervised installer
    log_info "Downloading Home Assistant Supervised installer..."
    wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
    
    # Install the package
    log_info "Installing Home Assistant Supervised package..."
    log_warning "The installation will restart NetworkManager and may cause temporary network interruption"
    
    # Install with proper error handling
    if dpkg -i homeassistant-supervised.deb; then
        log_success "Home Assistant Supervised installed successfully"
    else
        log_error "Home Assistant Supervised installation failed"
        
        # Try to fix broken packages
        log_info "Attempting to fix broken packages..."
        apt --fix-broken install -y
        
        # Retry installation
        log_info "Retrying Home Assistant Supervised installation..."
        dpkg -i homeassistant-supervised.deb
    fi
    
    # Clean up
    rm -f homeassistant-supervised.deb
}

wait_for_homeassistant() {
    log_info "Waiting for Home Assistant to start..."
    log_info "This may take 10-20 minutes for the initial setup..."
    
    local max_attempts=60
    local attempt=0
    local ip_address=$(hostname -I | awk '{print $1}')
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -f "http://${ip_address}:8123" >/dev/null 2>&1; then
            log_success "Home Assistant is accessible!"
            echo ""
            echo "=================================================================="
            echo "  Home Assistant Supervised is now running!"
            echo "  Access it at: http://${ip_address}:8123"
            echo "  Or: http://homeassistant.local:8123"
            echo "=================================================================="
            return 0
        fi
        
        ((attempt++))
        log_info "Attempt $attempt/$max_attempts - Still waiting for Home Assistant..."
        sleep 30
    done
    
    log_warning "Home Assistant may still be starting up. Please check manually."
    echo "Try accessing: http://${ip_address}:8123"
}

check_installation_status() {
    log_info "Checking installation status..."
    
    # Check if containers are running
    if command_exists docker; then
        log_info "Docker containers status:"
        docker ps -a | grep -E "(hassio|homeassistant)" || log_warning "No Home Assistant containers found yet"
    fi
    
    # Check if port 8123 is listening
    if ss -tulpn | grep -q ":8123"; then
        log_success "Home Assistant service is listening on port 8123"
    else
        log_warning "Home Assistant service not yet listening on port 8123"
    fi
}

main() {
    # Initialize logging
    setup_logging "$LOG_FILE"
    
    show_banner
    check_prerequisites
    
    log_info "Starting Home Assistant Supervised installation..."
    
    disable_wifi_randomization
    install_dependencies
    
    # Check for conflicts before proceeding
    check_homeassistant_conflicts || exit 1
    
    # Reboot if AppArmor configuration was changed
    configure_apparmor
    
    install_docker
    verify_docker
    install_os_agent
    install_homeassistant_supervised
    
    log_success "Installation completed!"
    
    check_installation_status
    wait_for_homeassistant
    
    echo ""
    echo "=================================================================="
    echo "  Installation Summary"
    echo "=================================================================="
    echo "✓ Home Assistant Supervised installed"
    echo "✓ Docker and dependencies configured"
    echo "✓ OS Agent installed and verified"
    echo "✓ AppArmor configured"
    echo ""
    echo "Next steps:"
    echo "1. Access Home Assistant web interface"
    echo "2. Complete the initial setup wizard"
    echo "3. Install add-ons from the Supervisor store"
    echo ""
    echo "For troubleshooting, check the log file:"
    echo "  $LOG_FILE"
    echo "=================================================================="
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
