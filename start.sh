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
readonly VERSION="1.0.1"
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
