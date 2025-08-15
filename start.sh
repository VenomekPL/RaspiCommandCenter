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
readonly VERSION="2.1.0-STABLE"
readonly LOG_FILE="${LOGS_DIR}/start_$(date +%Y%m%d_%H%M%S).log"

# Source utility functions
source "${UTILS_DIR}/logging.sh"
source "${UTILS_DIR}/common.sh"

###############################################################################
# Banner and Information
###############################################################################

show_banner() {
    echo "=================================================================="
    echo "  RaspiCommandCenter v${VERSION} - FULLY AUTOMATED"
    echo "  Complete Raspberry Pi 5 Entertainment Center Setup"
    echo "=================================================================="
    echo ""
    echo "🤖 FULL AUTOMATION: One command installs everything!"
    echo ""
    echo "⚠️  SAFETY FIRST - This script is designed for stability:"
    echo "• NO dangerous apt upgrade commands"
    echo "• NO risky firmware updates"
    echo "• NO EEPROM modifications that can brick your device"
    echo "• Conservative overclocking for reliability"
    echo ""
    echo "✅ Your system will remain stable and functional!"
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

create_summary_report() {
    local report_file="${LOGS_DIR}/complete_setup_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
RaspiCommandCenter Complete Setup Summary Report
===============================================
Date: $(date)
Version: ${VERSION}
System: $(cat /proc/device-tree/model | tr -d '\0' 2>/dev/null || echo 'Unknown')

COMPLETED TASKS:
✓ System dependencies installed (safe - no apt upgrade)
✓ Conservative performance optimization configured
  - CPU: 2.6 GHz safe overclock
  - GPU: 800 MHz stock frequency
  - Voltage: +1 (conservative)
  - Temperature limit: 80°C
  - NVME support enabled (no EEPROM changes)
✓ System services configured
  - SSH enabled for remote access
  - Docker installed and configured
  - Network stability preserved
✓ Home Assistant Supervised installed
✓ EmulationStation + RetroPie gaming platform installed

SYSTEM ACCESS:
- SSH: ssh $(whoami)@$(hostname).local
- IP: $(hostname -I | awk '{print $1}')
- Home Assistant: http://$(hostname -I | awk '{print $1}'):8123

NEXT STEPS AFTER REBOOT:
1. Access EmulationStation (auto-starts)
2. Configure Home Assistant via web interface
3. Add ROM files to ~/ROMs/<system>/ directories

LOGS:
- Main log: $LOG_FILE
- This summary: $report_file
EOF
    
    log_info "Complete setup summary created: $report_file"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    # Initialize
    create_directories
    
    # Start logging
    echo "=== RaspiCommandCenter Complete Auto-Setup Log ===" > "$LOG_FILE"
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
    
    log_info "Starting AUTOMATED RaspiCommandCenter complete setup..."
    echo ""
    echo "🚀 FULL AUTOMATION ENABLED - No manual steps required!"
    echo ""
    echo "This will automatically install and configure:"
    echo "• System dependencies and essential packages"
    echo "• Conservative performance optimization (2.6GHz CPU, 800MHz GPU)"
    echo "• NVME SSD support (device tree only - no EEPROM changes)"
    echo "• System services and Docker platform"
    echo "• Home Assistant Supervised"
    echo "• EmulationStation + RetroPie gaming platform"
    echo ""
    
    # Single confirmation prompt for everything
    read -p "Continue with COMPLETE automated setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled by user"
        exit 0
    fi
    
    # Execute ALL phases automatically
    echo ""
    echo "=================================================================="
    echo "  🤖 AUTOMATED INSTALLATION STARTING"
    echo "=================================================================="
    
    # Phase 1: System Foundation
    run_dependencies_installation
    run_performance_configuration  
    run_services_configuration
    
    # Phase 2: Applications (auto-run without prompts)
    log_info "=== Phase 2: Installing Applications (Automated) ==="
    echo ""
    
    if [[ -x "${SCRIPTS_DIR}/phase2.sh" ]]; then
        log_info "Starting Phase 2 automatically (Home Assistant + EmulationStation)..."
        "${SCRIPTS_DIR}/phase2.sh"
        if [[ $? -eq 0 ]]; then
            log_success "Phase 2 completed successfully"
        else
            log_error "Phase 2 failed"
            exit 1
        fi
    else
        log_error "Phase 2 script not found: ${SCRIPTS_DIR}/phase2.sh"
        exit 1
    fi
    
    # Create summary and show completion
    create_summary_report
    
    echo ""
    echo "=================================================================="
    echo "  🎉 COMPLETE AUTOMATED SETUP FINISHED!"
    echo "=================================================================="
    echo "✅ Phase 1: System foundation configured"
    echo "✅ Phase 2: Applications installed"
    echo "✅ Home Assistant Supervised ready"
    echo "✅ EmulationStation gaming platform ready"
    echo ""
    echo "🔄 FINAL STEP: System reboot required"
    echo "Hardware optimizations need a reboot to take effect."
    echo ""
    
    # Auto-reboot prompt
    read -p "Reboot now to complete setup? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_info "Rebooting system to activate all optimizations..."
        echo ""
        echo "🔄 Rebooting in 5 seconds... (Ctrl+C to cancel)"
        sleep 5
        reboot
    else
        echo ""
        echo "⚠️  MANUAL REBOOT REQUIRED:"
        echo "Run 'sudo reboot' when ready to activate all optimizations"
        echo ""
        log_success "Complete setup finished! Reboot manually when convenient."
    fi
}

# Execute main function
main "$@"
