#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

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
    card 0
}
EOF
    
    # Enable and start audio services
    if systemctl list-unit-files | grep -q pulseaudio; then
        systemctl --global enable pulseaudio.service
        log_info "PulseAudio service enabled"
    fi
    
    log_success "Audio services configured"
}

configure_network_services() {
    log_info "Configuring network services (SAFE - no NetworkManager changes)..."
    
    # DO NOT enable NetworkManager - causes network conflicts
    # Keep existing network configuration (dhcpcd + wpa_supplicant)
    log_info "Preserving existing network configuration for stability"
    
    # Enable Avahi for .local domain resolution
    systemctl enable avahi-daemon
    systemctl start avahi-daemon
    
    # Configure hostname resolution
    local hostname=$(hostname)
    log_info "System will be accessible as: ${hostname}.local"
    
    # Optimize network performance
    mkdir -p /etc/sysctl.d
    cat > /etc/sysctl.d/99-network-performance.conf << 'EOF'
# Network performance optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 16384 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_congestion_control = bbr
EOF
    
    log_success "Network services configured"
    
    # Test network connectivity
    log_info "Testing network connectivity..."
    sleep 3  # Give services time to start
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Network connectivity verified"
    else
        log_warn "Network connectivity test failed"
        log_info "This may be temporary - checking again in 10 seconds..."
        sleep 10
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log_success "Network connectivity restored"
        else
            log_error "Network connectivity still failing - manual network configuration may be needed"
        fi
    fi
}

configure_hardware_services() {
    log_info "Configuring hardware interface services..."
    
    # Enable I2C and SPI if modules are loaded
    if lsmod | grep -q i2c_bcm2835; then
        log_info "I2C support detected and enabled"
        
        # Add user to i2c group
        if [[ -n "${SUDO_USER:-}" ]]; then
            usermod -a -G i2c "$SUDO_USER"
        fi
    fi
    
    if lsmod | grep -q spi_bcm2835; then
        log_info "SPI support detected and enabled"
        
        # Add user to spi group  
        if [[ -n "${SUDO_USER:-}" ]]; then
            usermod -a -G spi "$SUDO_USER"
        fi
    fi
    
    # Configure GPIO permissions
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -a -G gpio "$SUDO_USER"
        log_info "Added $SUDO_USER to gpio group"
    fi
    
    log_success "Hardware interface services configured"
}

###############################################################################
# Docker Configuration
###############################################################################

configure_docker_service() {
    log_info "Configuring Docker service..."
    
    # Ensure Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found! Please run install_dependencies.sh first."
        return 1
    fi
    
    # Check for Docker conflicts before starting
    check_docker_conflicts "Docker" "" "" || {
        log_warning "Docker conflicts detected but continuing with service configuration"
    }
    
    # Enable Docker service
    systemctl enable docker
    systemctl start docker
    
    # Configure Docker daemon for optimal performance
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "dns": ["8.8.8.8", "8.8.4.4"],
    "dns-search": ["local"],
    "experimental": false,
    "live-restore": true
}
EOF
    
    # Restart Docker to apply configuration
    systemctl restart docker
    
    # Verify Docker is working
    if docker run --rm hello-world &>/dev/null; then
        log_success "Docker service configured and verified"
    else
        log_warn "Docker may not be working correctly"
    fi
}

###############################################################################
# System Optimization Services
###############################################################################


create_maintenance_scripts() {
    log_info "Creating system maintenance scripts..."
    
    # Create system cleanup script
    cat > /usr/local/bin/raspi-cleanup.sh << 'EOF'
#!/bin/bash
# RaspiCommandCenter System Cleanup Script

echo "Starting system cleanup..."

# Clean package cache (conservative)
apt autoclean

# Clean logs older than 30 days
journalctl --vacuum-time=30d

# Clean temporary files
find /tmp -type f -atime +7 -delete 2>/dev/null || true
find /var/tmp -type f -atime +7 -delete 2>/dev/null || true

# Clean Docker if installed
if command -v docker >/dev/null; then
    docker system prune -f
fi

# Trim SSD if present
fstrim -av 2>/dev/null || true

echo "System cleanup completed"
EOF
    
    chmod +x /usr/local/bin/raspi-cleanup.sh
    
    # Create system status script
    cat > /usr/local/bin/raspi-status.sh << 'EOF'
#!/bin/bash
# RaspiCommandCenter System Status Script

echo "=== RaspiCommandCenter System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo ""

# Temperature
if command -v vcgencmd >/dev/null; then
    echo "CPU Temperature: $(vcgencmd measure_temp)"
    echo "Throttling Status: $(vcgencmd get_throttled)"
else
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        echo "CPU Temperature: ${temp}°C"
    fi
fi

# CPU and Memory
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo ""

# Storage
echo "=== Storage Usage ==="
df -h | grep -E "(Filesystem|/dev/)"
echo ""

# Services
echo "=== Key Services ==="
services=("ssh" "docker" "NetworkManager" "bluetooth")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✓ $service: Active"
    else
        echo "✗ $service: Inactive"
    fi
done
echo ""

# Network
echo "=== Network ==="
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "Hostname: $(hostname).local"
EOF
    
    chmod +x /usr/local/bin/raspi-status.sh
    
    # Schedule weekly cleanup
    cat > /etc/cron.d/raspi-maintenance << 'EOF'
# RaspiCommandCenter Maintenance Tasks
0 3 * * 0 root /usr/local/bin/raspi-cleanup.sh >/dev/null 2>&1
EOF
    
    log_success "Maintenance scripts created"
}

###############################################################################
# Final System Configuration
###############################################################################

apply_final_tweaks() {
    log_info "Applying final system tweaks..."
    
    # Set timezone (you may want to customize this)
    timedatectl set-timezone UTC
    log_info "Timezone set to UTC (customize as needed)"
    
    # Configure logrotate for better log management
    cat > /etc/logrotate.d/raspi-logs << 'EOF'
/var/log/raspi-*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
    
    # Set up .bashrc aliases for convenience
    if [[ -n "${SUDO_USER:-}" ]]; then
        local user_home=$(eval echo "~$SUDO_USER")
        cat >> "$user_home/.bashrc" << 'EOF'

# RaspiCommandCenter Aliases
alias raspi-status='/usr/local/bin/raspi-status.sh'
alias raspi-cleanup='/usr/local/bin/raspi-cleanup.sh'
alias raspi-temp='vcgencmd measure_temp'
alias raspi-throttle='vcgencmd get_throttled'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF
        chown "$SUDO_USER:$SUDO_USER" "$user_home/.bashrc"
        log_info "Added convenience aliases to user .bashrc"
    fi
    
    log_success "Final system tweaks applied"
}

###############################################################################
# Service Validation
###############################################################################

validate_services() {
    log_info "Validating service configuration..."
    
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
    log_success "Service validation completed"
}

###############################################################################
# Main execution
###############################################################################

main() {
    log_info "=== Services Configuration Script ==="
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
    log_info "Starting SAFE services configuration..."
    
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
    
    log_success "=== Services configuration completed! ==="
    echo ""
    echo "All system services have been configured and optimized."
    echo "The system is ready for application installation."
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
