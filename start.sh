#!/bin/bash

###############################################################################
# Raspberry Pi 5 Setup Script - Main Entry Point
# 
# This script orchestrates the modular setup of a Raspberry Pi 5
# with NVME SSD, solid cooling, and all required components
#
# Author: RaspiCommandCenter
# Version: 2.0.0
###############################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
UTILS_DIR="${SCRIPT_DIR}/utils"
LOGS_DIR="${SCRIPT_DIR}/logs"

# Configuration
readonly PROGRAM_NAME="RaspiCommandCenter"
readonly VERSION="2.0.0"
readonly LOG_FILE="${LOGS_DIR}/start_$(date +%Y%m%d_%H%M%S).log"

# Source utility functions
source "${UTILS_DIR}/logging.sh"
source "${UTILS_DIR}/common.sh"

###############################################################################
# Banner and Information
###############################################################################

show_banner() {
    echo "=================================================================="
    echo "  RaspiCommandCenter v${VERSION}"
    echo "  Phase 1: System Preparation and Optimization"
    echo "=================================================================="
    echo ""
}

show_system_info() {
    log_info "System Information:"
    echo "  Date: $(date)"
    echo "  System: $(cat /proc/device-tree/model | tr -d '\0' 2>/dev/null || echo 'Unknown')"
    echo "  Kernel: $(uname -r)"
    echo "  User: $(whoami)"
    echo "  Architecture: $(uname -m)"
    
    # Memory info
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$(( mem_total / 1024 / 1024 ))
    echo "  Memory: ${mem_gb}GB"
    
    # Storage info
    local storage=$(df -h / | awk 'NR==2 {print $2}')
    echo "  Root Storage: $storage"
    
    echo ""
}
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_kb / 1024 / 1024))
    echo "  Memory: ${mem_gb}GB"
    
    echo ""
}

###############################################################################
# Prerequisites and Validation
###############################################################################

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check if this is a Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        log_warn "This script is optimized for Raspberry Pi hardware"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error "No internet connection detected. Please connect to internet and try again."
        exit 1
    fi
    
    # Check available disk space (need at least 2GB free)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then  # 2GB in KB
        log_error "Insufficient disk space. Need at least 2GB free."
        exit 1
    fi
    
    # Verify modular scripts exist
    local required_scripts=(
        "${SCRIPTS_DIR}/install_dependencies.sh"
        "${SCRIPTS_DIR}/configure_performance.sh"
        "${SCRIPTS_DIR}/configure_services.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            log_error "Required script not found: $script"
            exit 1
        fi
        
        if [[ ! -x "$script" ]]; then
            log_info "Making script executable: $script"
            chmod +x "$script"
        fi
    done
    
    log_success "Prerequisites check passed"
}

###############################################################################
# Directory Management
###############################################################################

create_directories() {
    log_info "Creating necessary directories..."
    
    # Create directory structure
    local dirs=(
        "$LOGS_DIR"
        "${SCRIPT_DIR}/config"
        "${SCRIPT_DIR}/backups"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
}

###############################################################################
# Modular Script Execution
###############################################################################

run_dependencies_installation() {
    log_info "=== Phase 1.1: Installing Dependencies ==="
    echo ""
    
    if [[ -x "${SCRIPTS_DIR}/install_dependencies.sh" ]]; then
        "${SCRIPTS_DIR}/install_dependencies.sh"
        if [[ $? -eq 0 ]]; then
            log_success "Dependencies installation completed successfully"
        else
            log_error "Dependencies installation failed"
            exit 1
        fi
    else
        log_error "Dependencies installation script not found or not executable"
        exit 1
    fi
}

run_performance_configuration() {
    log_info "=== Phase 1.2: Configuring Performance ==="
    echo ""
    
    if [[ -x "${SCRIPTS_DIR}/configure_performance.sh" ]]; then
        "${SCRIPTS_DIR}/configure_performance.sh"
        if [[ $? -eq 0 ]]; then
            log_success "Performance configuration completed successfully"
        else
            log_error "Performance configuration failed"
            exit 1
        fi
    else
        log_error "Performance configuration script not found or not executable"
        exit 1
    fi
}

run_services_configuration() {
    log_info "=== Phase 1.3: Configuring Services ==="
    echo ""
    
    if [[ -x "${SCRIPTS_DIR}/configure_services.sh" ]]; then
        "${SCRIPTS_DIR}/configure_services.sh"
        if [[ $? -eq 0 ]]; then
            log_success "Services configuration completed successfully"
        else
            log_error "Services configuration failed"
            exit 1
        fi
    else
        log_error "Services configuration script not found or not executable"
        exit 1
    fi
}

###############################################################################
# Completion and Next Steps
###############################################################################

show_next_steps() {
    echo ""
    echo "=================================================================="
    echo "  PHASE 1 SETUP COMPLETED SUCCESSFULLY!"
    echo "=================================================================="
    echo ""
    echo "✅ System dependencies installed"
    echo "✅ Performance optimizations configured"
    echo "✅ Hardware settings optimized" 
    echo "✅ System services configured"
    echo ""
    echo "NEXT: Install Applications (no reboot needed for software)"
    echo "   - ./scripts/setup_homeassistant.sh (Home Assistant Supervised)"
    echo "   - ./scripts/setup_emulationstation.sh (RetroPie + Controller automation)"
    echo "   - ./scripts/setup_kodi.sh (Kodi media center - optional)"
    echo "   - ./scripts/phase2.sh (runs Home Assistant + EmulationStation together)"
    echo ""
    echo "FINAL STEP: Manual Reboot When All Installations Complete"
    echo "   - Command: sudo reboot"
    echo "   - Purpose: Activates hardware optimizations (CPU, GPU, NVME, etc.)"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    echo "WORKFLOW: Install everything → Manual reboot at the very end! 🚀"
    echo "=================================================================="
}

create_summary_report() {
    local report_file="${LOGS_DIR}/phase1_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
RaspiCommandCenter Phase 1 Summary Report
==========================================
Date: $(date)
Version: ${VERSION}
System: $(cat /proc/device-tree/model | tr -d '\0' 2>/dev/null || echo 'Unknown')

COMPLETED TASKS:
✓ System dependencies installed
✓ Performance optimization configured
  - CPU: 3.0 GHz overclock
  - GPU: 1.0 GHz overclock
  - NVME PCIe Gen 3 enabled
  - 4K video acceleration enabled
✓ System services configured
  - SSH enabled for remote access
  - Docker installed and configured
  - Bluetooth optimized for controllers
  - Network services configured

NEXT STEPS:
1. Reboot the system
2. Run Phase 2 applications:
   - Home Assistant Supervised
   - EmulationStation + Kodi integration

SYSTEM ACCESS:
- SSH: ssh $(whoami)@$(hostname).local
- IP: $(hostname -I | awk '{print $1}')

LOGS:
- Main log: $LOG_FILE
- This summary: $report_file
EOF
    
    log_info "Summary report created: $report_file"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    # Initialize
    create_directories
    
    # Start logging
    echo "=== RaspiCommandCenter Phase 1 Setup Log ===" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "Version: ${VERSION}" >> "$LOG_FILE"
    echo "System: $(cat /proc/device-tree/model | tr -d '\0' 2>/dev/null || echo 'Unknown')" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "============================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Display banner and info
    show_banner
    show_system_info
    
    # Run prerequisites check
    check_prerequisites
    
    log_info "Starting RaspiCommandCenter Phase 1 setup..."
    echo ""
    echo "This will install and configure:"
    echo "• System dependencies and essential packages"
    echo "• Performance optimization (3GHz CPU, 1GHz GPU)"
    echo "• NVME SSD and PCIe configuration"
    echo "• System services and Docker platform"
    echo ""
    
    # Confirmation prompt
    read -p "Continue with Phase 1 setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled by user"
        exit 0
    fi
    
    # Execute modular setup phases
    run_dependencies_installation
    run_performance_configuration  
    run_services_configuration
    
    # Create summary and show next steps
    create_summary_report
    show_next_steps
    
    log_success "Phase 1 setup completed successfully!"
    
    # Show completion message
    echo ""
    echo "SETUP COMPLETE!"
    echo "You can now run application setup scripts:"
    echo "• ./scripts/setup_homeassistant.sh (Home Assistant Supervised)"
    echo "• ./scripts/setup_emulationstation.sh (RetroPie + Controller automation)"
    echo "• ./scripts/setup_kodi.sh (Kodi media center - optional)"
    echo "• ./scripts/phase2.sh (runs Home Assistant + EmulationStation together)"
    echo ""
    echo "WHEN ALL INSTALLATIONS ARE COMPLETE:"
    echo "• Manual reboot recommended: sudo reboot"
    echo "• This activates hardware optimizations (CPU overclocking, GPU settings, etc.)"
    echo ""
    log_success "Phase 1 completed! Continue with application installations, then reboot manually when done."
}

# Execute main function
main "$@"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $message" >> "$LOG_FILE"
}

show_banner() {
    echo "=================================================================="
    echo "  ${PROGRAM_NAME} v${VERSION}"
    echo "  Raspberry Pi 5 Complete Setup & Configuration"
    echo "=================================================================="
    echo ""
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        log_error "This script must be run on a Raspberry Pi"
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check if running on Pi 5
    local pi_model=$(cat /proc/device-tree/model | tr -d '\0')
    if [[ ! "$pi_model" =~ "Raspberry Pi 5" ]]; then
        log_warning "This script is optimized for Raspberry Pi 5. Current model: $pi_model"
        read -p "Continue anyway? (y/N): " choice
        [[ "$choice" =~ ^[Yy]$ ]] || exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &>/dev/null; then
        log_error "No internet connectivity detected. Internet is required for this setup."
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p "$LOGS_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$SCRIPTS_DIR"
    
    log_success "Directories created"
}

update_system() {
    log_info "Updating system packages..."
    
    # Update package lists
    apt-get update -y
    
    # Upgrade existing packages
    apt-get upgrade -y
    
    # Clean up
    apt-get autoremove -y
    apt-get autoclean
    
    log_success "System update completed"
}

install_requirements() {
    log_info "Installing requirements from requirements.txt..."
    
    local requirements_file="${SCRIPT_DIR}/requirements.txt"
    
    if [[ ! -f "$requirements_file" ]]; then
        log_error "requirements.txt not found at $requirements_file"
        exit 1
    fi
    
    # Read and install each package
    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
        
        log_info "Installing: $package"
        if apt-get install -y "$package"; then
            log_success "Installed: $package"
        else
            log_warning "Failed to install: $package"
        fi
    done < "$requirements_file"
    
    log_success "Requirements installation completed"
}

configure_boot_config() {
    log_info "Configuring boot configuration for Raspberry Pi 5..."
    
    local config_file="/boot/firmware/config.txt"
    
    # Check if config.txt exists in different locations
    if [[ ! -f "$config_file" ]]; then
        config_file="/boot/config.txt"
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Boot config file not found"
        exit 1
    fi
    
    # Backup original config
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backup created: ${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add our configuration section
    cat >> "$config_file" << 'EOF'

# RaspiCommandCenter Configuration
# Added by start.sh script

# NVME SSD Support and PCIe Configuration
dtparam=pcie=on
dtparam=pciex1_gen=3
dtoverlay=pcie-32bit-dma

# Video and GPU Configuration
dtoverlay=vc4-kms-v3d-pi5
dtoverlay=rpivid-v4l2
hdmi_enable_4kp60=1
hdmi_force_hotplug=1

# Audio Configuration
dtparam=audio=on
audio_pwm_mode=1

# Performance and Cooling (Optimized for Pironman5)
temp_limit=80
temp_soft_limit=70
force_turbo=1
arm_freq=3000
arm_freq_min=1800
gpu_freq=1000
over_voltage=4
over_voltage_min=2

# CMA Memory for 4K Video
dtoverlay=cma,cma-512

# GPIO and Hardware
dtparam=spi=on
dtparam=i2c_arm=on

# End RaspiCommandCenter Configuration
EOF
    
    log_success "Boot configuration updated"
}

configure_nvme_boot() {
    log_info "Configuring NVME boot priority..."
    
    # Check if raspi-config is available
    if command -v raspi-config &> /dev/null; then
        # Use raspi-config to set boot order (NVME first, then SD)
        raspi-config nonint do_boot_order B2
        log_success "Boot order set to NVME first via raspi-config"
    else
        log_warning "raspi-config not available, manual EEPROM configuration may be needed"
    fi
    
    # Update bootloader if needed
    if [[ -d "/lib/firmware/raspberrypi/bootloader" ]]; then
        log_info "Updating bootloader firmware..."
        rpi-eeprom-update -a
        log_success "Bootloader updated"
    fi
}

enable_services() {
    log_info "Enabling necessary services..."
    
    # Enable SSH if not already enabled
    systemctl enable ssh
    systemctl start ssh
    
    # Enable I2C and SPI if modules are loaded
    if lsmod | grep -q i2c_bcm2835; then
        log_info "I2C support detected and enabled"
    fi
    
    if lsmod | grep -q spi_bcm2835; then
        log_info "SPI support detected and enabled"
    fi
    
    log_success "Services configuration completed"
}

install_docker() {
    log_info "Installing Docker..."
    
    # Install Docker using official script
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        
        # Add current user to docker group (if not root)
        if [[ -n "${SUDO_USER:-}" ]]; then
            usermod -aG docker "$SUDO_USER"
            log_info "Added $SUDO_USER to docker group"
        fi
        
        log_success "Docker installed successfully"
    else
        log_info "Docker already installed"
    fi
}

show_next_steps() {
    echo ""
    echo "=================================================================="
    echo "  PHASE 1 SETUP COMPLETED SUCCESSFULLY!"
    echo "=================================================================="
    echo ""
    echo "Phase 1 (System Preparation) is complete. Next phases:"
    echo ""
    echo "PHASE 2 - Core Applications:"
    echo "1. REBOOT your Raspberry Pi to apply all configuration changes"
    echo "2. After reboot, run setup scripts in order:"
    echo "   - ./scripts/setup_homeassistant.sh (Home Assistant Supervised)"
    echo "   - ./scripts/setup_emulationstation.sh (RetroPie + Kodi integration)"
    echo ""
    echo "PHASE 3 - Optional Features:"
    echo "   - ./scripts/setup_kodi.sh (Enhanced Kodi with Elementum torrent streaming)"
    echo "   - ./scripts/setup_nas_fileserver.sh (Samba NAS + Webmin for file sharing)"
    echo "   - ./scripts/configure_boot_cli.sh (Command line boot + EmulationStation auto-start)"
    echo ""
    echo "Web Services (after setup):"
    echo "   - Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
    echo "   - Kodi Web Interface: http://$(hostname -I | awk '{print $1}'):8080"
    echo "   - Webmin (NAS): http://$(hostname -I | awk '{print $1}'):10000"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    echo "IMPORTANT: A reboot is required to activate NVME and hardware changes!"
    echo "=================================================================="
}

###############################################################################
# Main Execution
###############################################################################

main() {
    # Initialize
    create_directories
    
    # Start logging
    echo "=== RaspiCommandCenter Setup Log ===" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "System: $(cat /proc/device-tree/model | tr -d '\0')" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "============================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    show_banner
    check_prerequisites
    
    log_info "Starting Raspberry Pi 5 configuration..."
    
    # Phase 1: System Update and Requirements
    update_system
    install_requirements
    
    # Phase 2: Boot and Hardware Configuration
    configure_boot_config
    configure_nvme_boot
    
    # Phase 3: Services and Additional Software
    enable_services
    install_docker
    
    # Complete
    log_success "All configuration completed successfully!"
    show_next_steps
    
    # Ask for reboot
    echo ""
    read -p "Reboot now to apply all changes? (y/N): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        log_info "Rebooting system..."
        reboot
    else
        log_info "Remember to reboot manually to apply all changes"
    fi
}

# Execute main function
main "$@"
