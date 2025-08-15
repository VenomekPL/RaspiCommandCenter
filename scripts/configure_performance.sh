#!/bin/bash

set -euo pipefail

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
