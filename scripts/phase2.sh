#!/bin/bash

# RaspiCommandCenter - Phase 2 Setup Launcher
# This script runs the Phase 2 setup components

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

show_banner() {
    echo "=================================================================="
    echo "  RaspiCommandCenter - Phase 2 Setup"
    echo "  Home Assistant + EmulationStation + Kodi Integration"
    echo "=================================================================="
    echo ""
}

main() {
    show_banner
    
    log_info "Starting Phase 2 setup..."
    echo ""
    echo "This will install:"
    echo "1. Home Assistant Supervised (containerized smart home platform)"
    echo "2. EmulationStation with all major retro gaming emulators"
    echo "3. Kodi integrated as a port within EmulationStation"
    echo "4. Seamless switching between Kodi and EmulationStation"
    echo ""
    
    read -p "Continue with Phase 2 installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Check if Phase 1 was completed
    config_found=false
    
    # Check both possible boot config locations
    for config_file in "/boot/firmware/config.txt" "/boot/config.txt"; do
        if [[ -f "$config_file" ]] && grep -q "RaspiCommandCenter Configuration" "$config_file" 2>/dev/null; then
            config_found=true
            log_info "Phase 1 configuration detected in $config_file"
            break
        fi
    done
    
    if [[ "$config_found" != "true" ]]; then
        log_warning "Phase 1 configuration not detected in boot config"
        log_warning "It's recommended to run ./start.sh first for optimal performance"
        echo ""
        read -p "Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled. Run ./start.sh first for best results."
            exit 0
        fi
    fi
    
    echo ""
    log_info "=== Installing Home Assistant Supervised ==="
    if [ -x "${SCRIPT_DIR}/setup_homeassistant.sh" ]; then
        "${SCRIPT_DIR}/setup_homeassistant.sh"
        log_success "Home Assistant installation completed"
    else
        log_error "Home Assistant setup script not found or not executable"
        exit 1
    fi
    
    echo ""
    log_info "=== Installing EmulationStation + Kodi Integration ==="
    if [ -x "${SCRIPT_DIR}/setup_emulationstation.sh" ]; then
        "${SCRIPT_DIR}/setup_emulationstation.sh"
        log_success "EmulationStation + Kodi installation completed"
    else
        log_error "EmulationStation setup script not found or not executable"
        exit 1
    fi
    
    echo ""
    echo "=================================================================="
    echo "  PHASE 2 SETUP COMPLETED!"
    echo "=================================================================="
    echo ""
    echo "Your Raspberry Pi is now configured with:"
    echo "✓ Home Assistant Supervised (accessible at http://[PI-IP]:8123)"
    echo "✓ EmulationStation with automatic controller support"
    echo "✓ ROM directories organized in ~/ROMs/ with proper platform names"
    echo "✓ All major retro gaming emulators (50+ cores)"
    echo "✓ Kodi integration available (run ./setup_kodi.sh if desired)"
    echo ""
    echo "Optional Additional Setup:"
    echo "• Advanced Kodi: Run ./setup_kodi.sh for enhanced media center with Elementum"
    echo "• NAS File Server: Run ./setup_nas_fileserver.sh for home directory sharing"
    echo "• Boot Optimization: Run ./configure_boot_cli.sh for command line boot + auto-start EmulationStation"
    echo ""
    echo "Web Services Access:"
    echo "• Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
    echo "• Kodi Web Interface: http://$(hostname -I | awk '{print $1}'):8080 (after Kodi setup)"
    echo "• Webmin (NAS): http://$(hostname -I | awk '{print $1}'):10000 (after NAS setup)"
    echo ""
    echo "Next Steps:"
    echo "1. If you ran ./start.sh first: Reboot to activate hardware optimizations"
    echo "2. Access Home Assistant at http://$(hostname -I | awk '{print $1}'):8123"
    echo "3. Start EmulationStation: 'emulationstation' command"
    echo "4. Add ROM files to ~/ROMs/<system>/ folders"
    echo "5. Controllers will be detected and configured automatically"
    echo ""
    echo "REBOOT HELPER: Run ../reboot-when-ready.sh to check if reboot is needed"
    echo "=================================================================="
}

# Execute main function
main "$@"
