#!/bin/bash

set -euo pipefail

configure_ssh_service() {
    echo "Configuring SSH service..."
    systemctl enable ssh
    systemctl start ssh
    echo "✓ SSH enabled"
}

configure_bluetooth_service() {
    echo "Configuring Bluetooth for controllers..."
    
    systemctl enable bluetooth
    systemctl start bluetooth
    
    # Optimize Bluetooth for gaming controllers
    mkdir -p /etc/modprobe.d
    cat > /etc/modprobe.d/xbox_bt.conf << 'EOF'
options bluetooth disable_ertm=Y
EOF
    
    mkdir -p /etc/bluetooth/main.conf.d
    cat > /etc/bluetooth/main.conf.d/raspi-optimization.conf << 'EOF'
[General]
Class=0x000100
DiscoverableTimeout=0
PairableTimeout=0

[Policy]
AutoEnable=true
EOF
    
    echo "✓ Bluetooth optimized for controllers"
}

configure_audio_services() {
    echo "Configuring audio services..."
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -a -G audio "$SUDO_USER"
    fi
    
    cat > /etc/asound.conf << 'EOF'
pcm.!default {
    type hw
    card 0
    device 0
}

ctl.!default {
    type hw
    card 0
}
EOF
    
    echo "✓ Audio configured"
}

configure_console_boot() {
    echo "Configuring console boot (no desktop)..."
    
    # Set boot to console mode instead of desktop
    systemctl set-default multi-user.target
    
    echo "✓ Console boot configured"
}

configure_emulationstation_autostart() {
    echo "Configuring EmulationStation autostart..."
    
    USER_HOME="/home/${SUDO_USER:-$USER}"
    
    # Create .profile for user to autostart EmulationStation
    cat > "$USER_HOME/.profile" << 'EOF'
# ~/.profile: executed by the command interpreter for login shells.

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Auto-start EmulationStation on console login (tty1 only)
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$SSH_CONNECTION" ]; then
    if command -v emulationstation >/dev/null 2>&1; then
        emulationstation
    fi
fi
EOF
    
    chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$USER_HOME/.profile"
    
    echo "✓ EmulationStation autostart configured"
}

main() {
    echo "=== Configuring Services ==="
    
    configure_ssh_service
    configure_bluetooth_service
    configure_audio_services
    configure_console_boot
    configure_emulationstation_autostart
    
    echo "=== Services configuration completed ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

###############################################################################
# Service Validation
###############################################################################

validate_services() {
    echo "Validating service configuration..."
    
    echo ""
    echo "=== Service Configuration Summary ==="
    
    # Check critical services
    local critical_services=("ssh" "NetworkManager" "avahi-daemon" "docker")
    for service in "${critical_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "✓ $service: Running"
        else
            echo "✗ $service: Not running"
        fi
    done
    
    # Check user groups
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo ""
        echo "=== User Group Memberships ==="
        local groups=$(groups "$SUDO_USER" | cut -d: -f2)
        echo "$SUDO_USER is member of:$groups"
    fi
    
    # Check network accessibility
    echo ""
    echo "=== Network Information ==="
    echo "IP Address: $(hostname -I | awk '{print $1}')"
    echo "Hostname: $(hostname).local"
    echo "SSH Access: ssh $(whoami)@$(hostname).local"
    
    echo ""
    echo "Service validation completed"
}

###############################################################################
# Main execution
###############################################################################

main() {
    echo "=== Services Configuration Script ==="
    echo ""
    echo "This script will configure:"
    echo "• SSH service for remote access"
    echo "• Bluetooth for gaming controllers"
    echo "• Audio services and optimization"
    echo "• Network services (safe - no changes to existing configuration)"
    echo "• Docker container platform"
    echo "• System maintenance and monitoring"
    echo ""
    
    # No confirmation needed - controlled by start.sh
    echo "Starting SAFE services configuration..."
    
    configure_ssh_service
    configure_bluetooth_service
    configure_audio_services
    configure_network_services
    configure_hardware_services
    configure_docker_service
    configure_system_services
    create_maintenance_scripts
    apply_final_tweaks
    
    # Validation and summary
    validate_services
    
    echo "=== Services configuration completed! ==="
    echo ""
    echo "All system services have been configured and optimized."
    echo "The system is ready for application installation."
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
