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
