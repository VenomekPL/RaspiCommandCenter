#!/bin/bash

###############################################################################
# Configure Boot to Command Line + Auto-start EmulationStation
# 
# This script configures the Raspberry Pi to:
# 1. Boot to command line (no desktop)
# 2. Auto-start EmulationStation after login
# 3. Return to command line when EmulationStation exits
###############################################################################

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

configure_boot_target() {
    log_info "Configuring boot target to command line..."
    
    # Set boot target to multi-user (command line)
    if sudo systemctl set-default multi-user.target; then
        log_success "Boot target set to command line mode"
    else
        log_error "Failed to set boot target"
        return 1
    fi
    
    # Disable automatic desktop login
    if sudo systemctl disable lightdm.service 2>/dev/null || true; then
        log_info "Desktop auto-login disabled"
    fi
}

configure_autologin() {
    log_info "Configuring automatic console login..."
    
    # Create autologin service override directory
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
    
    # Create autologin configuration
    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $(whoami) --noclear %I \$TERM
EOF
    
    log_success "Automatic console login configured for user: $(whoami)"
}

create_emulationstation_autostart() {
    log_info "Creating EmulationStation autostart configuration..."
    
    # Create autostart script
    local autostart_script="$HOME/.emulationstation_autostart.sh"
    
    cat > "$autostart_script" << 'EOF'
#!/bin/bash

# EmulationStation Autostart Script
# This script runs after login and starts EmulationStation
# When EmulationStation exits, it returns to command line

# Wait a moment for system to be ready
sleep 2

# Clear screen and show welcome message
clear
echo "=================================================================="
echo "  RaspiCommandCenter - Gaming System Ready"
echo "=================================================================="
echo ""
echo "Starting EmulationStation..."
echo "- To access command line: Exit EmulationStation (Start > Quit)"
echo "- To restart EmulationStation: Type 'emulationstation'"
echo "- To access web services:"
echo "  • Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
echo "  • Kodi Web Interface: http://$(hostname -I | awk '{print $1}'):8080"
echo "  • Webmin (NAS): http://$(hostname -I | awk '{print $1}'):10000"
echo ""
echo "=================================================================="
sleep 3

# Check if EmulationStation is installed
if command -v emulationstation >/dev/null 2>&1; then
    # Start EmulationStation
    emulationstation
    
    # When EmulationStation exits, show exit message
    clear
    echo "=================================================================="
    echo "  EmulationStation Exited - Command Line Ready"
    echo "=================================================================="
    echo ""
    echo "Available commands:"
    echo "  emulationstation    - Restart EmulationStation"
    echo "  kodi               - Start Kodi media center"
    echo "  htop               - System monitor"
    echo "  exit               - Logout"
    echo ""
    echo "Web Services:"
    echo "  Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
    echo "  Kodi Web: http://$(hostname -I | awk '{print $1}'):8080"
    echo "  Webmin: http://$(hostname -I | awk '{print $1}'):10000"
    echo "=================================================================="
else
    echo "EmulationStation not found. Please run setup_emulationstation.sh first."
    echo "System ready for manual use."
fi
EOF
    
    chmod +x "$autostart_script"
    log_success "EmulationStation autostart script created"
}

configure_bash_profile() {
    log_info "Configuring bash profile for autostart..."
    
    # Backup existing .bash_profile if it exists
    if [ -f "$HOME/.bash_profile" ]; then
        cp "$HOME/.bash_profile" "$HOME/.bash_profile.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing .bash_profile backed up"
    fi
    
    # Create or update .bash_profile
    cat > "$HOME/.bash_profile" << 'EOF'
# RaspiCommandCenter Auto-start Configuration
# This file runs when logging in to the console

# Source the regular .bashrc for normal shell setup
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Only run autostart on tty1 (main console) and if not already running
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$EMULATIONSTATION_AUTOSTART_RAN" ]; then
    export EMULATIONSTATION_AUTOSTART_RAN=1
    
    # Run the autostart script
    if [ -f ~/.emulationstation_autostart.sh ]; then
        ~/.emulationstation_autostart.sh
    fi
fi
EOF
    
    log_success "Bash profile configured for EmulationStation autostart"
}

create_helper_scripts() {
    log_info "Creating helper scripts..."
    
    # Create desktop starter script
    cat > "$HOME/start-desktop.sh" << 'EOF'
#!/bin/bash
# Start desktop environment from command line
echo "Starting desktop environment..."
sudo systemctl start lightdm.service
echo "Desktop started. Use Ctrl+Alt+F1 to return to console."
EOF
    chmod +x "$HOME/start-desktop.sh"
    
    # Create EmulationStation restart script
    cat > "$HOME/restart-es.sh" << 'EOF'
#!/bin/bash
# Quick restart EmulationStation
clear
echo "Restarting EmulationStation..."
emulationstation
EOF
    chmod +x "$HOME/restart-es.sh"
    
    log_success "Helper scripts created:"
    log_info "  ~/start-desktop.sh - Start desktop when needed"
    log_info "  ~/restart-es.sh - Quick EmulationStation restart"
}

show_completion_message() {
    echo ""
    echo "=================================================================="
    echo "  BOOT CONFIGURATION COMPLETED!"
    echo "=================================================================="
    echo ""
    echo "Changes applied:"
    echo "✓ Boot target set to command line (no desktop)"
    echo "✓ Automatic console login configured"
    echo "✓ EmulationStation will auto-start after boot"
    echo "✓ Helper scripts created in home directory"
    echo ""
    echo "After reboot:"
    echo "• System will boot directly to EmulationStation"
    echo "• Exit EmulationStation to access command line"
    echo "• Type 'emulationstation' to restart gaming"
    echo "• Run '~/start-desktop.sh' if desktop is needed"
    echo ""
    echo "Web Services Access:"
    echo "• Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
    echo "• Kodi Web Interface: http://$(hostname -I | awk '{print $1}'):8080"
    echo "• Webmin (NAS): http://$(hostname -I | awk '{print $1}'):10000"
    echo ""
    echo "REBOOT REQUIRED to apply boot configuration changes!"
    echo "=================================================================="
}

main() {
    log_info "Starting boot configuration for EmulationStation autostart..."
    
    # Verify user permissions
    if ! groups "$(whoami)" | grep -q sudo; then
        log_error "User $(whoami) is not in sudo group. Cannot configure system boot."
        exit 1
    fi
    
    # Apply configurations
    configure_boot_target
    configure_autologin
    create_emulationstation_autostart
    configure_bash_profile
    create_helper_scripts
    
    show_completion_message
    
    log_success "Boot configuration completed successfully!"
}

# Execute main function
main "$@"
