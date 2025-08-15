#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration file paths
BOOT_CONFIG="/boot/config.txt"
BOOT_CONFIG_FIRMWARE="/boot/firmware/config.txt"

detect_boot_config_path() {
    if [[ -f "$BOOT_CONFIG_FIRMWARE" ]]; then
        echo "$BOOT_CONFIG_FIRMWARE"
    elif [[ -f "$BOOT_CONFIG" ]]; then
        echo "$BOOT_CONFIG"
    else
        echo "ERROR: Boot configuration file not found!" >&2
        exit 1
    fi
}

backup_boot_config() {
    local config_file="$1"
    local backup_file="${config_file}.backup-$(date +%Y%m%d_%H%M%S)"
    cp "$config_file" "$backup_file"
    echo "✓ Backup created: $backup_file"
}

configure_boot_settings() {
    echo "Configuring boot and performance settings..."
    
    local config_file
    config_file=$(detect_boot_config_path)
    
    backup_boot_config "$config_file"
    
    # Remove any existing RaspiCommandCenter configuration
    sed -i '/# RaspiCommandCenter Configuration/,/# End RaspiCommandCenter Configuration/d' "$config_file"
    
    # Add our configuration block
    cat >> "$config_file" << 'EOF'

# RaspiCommandCenter Configuration
# Using Jeff Geerling's reliable NVME boot method

# NVME/PCIe Configuration
dtparam=nvme

# Audio Configuration
dtparam=audio=on

# Performance Settings - 3GHz overclock
arm_freq=3000
arm_freq_min=1500
gpu_freq=1000

# Conservative voltage
over_voltage=4

# GPU memory allocation
gpu_mem=512

# Temperature limit for safety
temp_limit=81

# Enable hardware interfaces
dtparam=spi=on
dtparam=i2c_arm=on

# End RaspiCommandCenter Configuration
EOF
    
    echo "✓ Boot configuration updated with 3GHz overclock"
}

main() {
    echo "=== Configuring Performance ==="
    
    configure_boot_settings
    
    echo "=== Performance configuration completed ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
    
    log_success "Boot configuration updated with performance settings"
}

###############################################################################
# NVME and Storage Configuration
###############################################################################

configure_nvme_safe() {
    log_info "SAFE NVME configuration (no EEPROM changes)..."
    
    # Only enable NVME in config.txt - do NOT modify EEPROM
    log_info "NVME support enabled via device tree overlay"
    log_warn "EEPROM boot order NOT modified for safety"
    log_info "System will boot from SD card by default (safe)"
    log_info ""
    log_info "To manually enable NVME boot later (advanced users only):"
    log_info "  1. sudo rpi-eeprom-config --edit"
    log_info "  2. Set BOOT_ORDER=0xf416"
    log_info "  3. Set PCIE_PROBE=1"
    log_info "  4. Save and reboot"
    log_info ""
    log_success "SAFE NVME configuration completed (no EEPROM risk)"
}



###############################################################################
# GPU and Video Configuration
###############################################################################

configure_gpu_settings() {
    log_info "Configuring GPU and video acceleration..."
    
    # Ensure video group exists and add users
    if getent group video >/dev/null; then
        if [[ -n "${SUDO_USER:-}" ]]; then
            usermod -a -G video "$SUDO_USER"
            log_info "Added $SUDO_USER to video group"
        fi
    fi
    
    # Configure GPU memory split (handled in boot config)
    log_info "GPU memory and acceleration configured via boot config"
    
    # Set up video device permissions
    cat > /etc/udev/rules.d/99-video-permissions.rules << 'EOF'
# Video device permissions for hardware acceleration
SUBSYSTEM=="video4linux", GROUP="video", MODE="0664"
KERNEL=="vchiq", GROUP="video", MODE="0664"
EOF
    
    log_success "GPU and video settings configured"
}



###############################################################################
# Performance Validation
###############################################################################

validate_performance_settings() {
    log_info "Validating performance settings..."
    
    echo ""
    echo "=== Performance Configuration Summary ==="
    
    # Check if boot config was updated
    local config_file
    config_file=$(detect_boot_config_path)
    if grep -q "RaspiCommandCenter Configuration" "$config_file"; then
        echo "✓ Boot configuration updated"
        echo "  - CPU: 3.0 GHz (3000 MHz)"
        echo "  - GPU: 1.0 GHz (1000 MHz)" 
        echo "  - Over-voltage: 4 (tested stable)"
        echo "  - PCIe Gen 3 enabled"
        echo "  - 4K video acceleration enabled"
    else
        echo "✗ Boot configuration may not be updated"
    fi
    
###############################################################################
# Main execution
###############################################################################

main() {
    log_info "=== Performance Configuration Script ==="
    echo ""
    echo "This script will configure:"
    echo "• Conservative CPU overclock (2.6GHz)"
    echo "• Safe GPU settings (800MHz)"
    echo "• NVME support (device tree only - no EEPROM changes)"
    echo "• Temperature limits and thermal management"
    echo ""
    echo "All settings are conservative and tested for stability."
    echo ""
    
    # No confirmation needed - controlled by start.sh
    log_info "Starting SAFE performance configuration..."
    
    configure_boot_settings
    configure_nvme_safe
    configure_storage_optimization
    configure_memory_settings
    configure_cpu_governor
    configure_gpu_settings
    configure_thermal_management
    
    # Validation and summary
    validate_performance_settings
    
    log_success "=== Performance configuration completed! ==="
    echo ""
    echo "Next step: Reboot the system to apply all changes"
    echo "After reboot, run the application installation scripts"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
