#!/bin/bash

###############################################################################
# Reboot Helper Script
# 
# Helps users reboot when they're ready to activate hardware changes
#
# Author: RaspiCommandCenter
# Version: 1.0.0
###############################################################################

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/logging.sh"
source "${SCRIPT_DIR}/utils/common.sh"

echo "=============================================="
echo "  REBOOT HELPER - RaspiCommandCenter"
echo "=============================================="
echo ""

# Check what changes require reboot
boot_changes_made=false
config_files=("/boot/config.txt" "/boot/firmware/config.txt")

for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ] && grep -q "RaspiCommandCenter" "$config_file" 2>/dev/null; then
        boot_changes_made=true
        break
    fi
done

if [ "$boot_changes_made" = true ]; then
    echo "✅ HARDWARE CHANGES DETECTED - Reboot Required"
    echo ""
    echo "The following hardware changes need a reboot to activate:"
    echo "• CPU overclocking and performance tuning"
    echo "• GPU memory allocation and video drivers"
    echo "• NVME boot priority and PCIe configuration"
    echo "• Device tree overlays for hardware features"
    echo ""
    
    # Check if applications are installed
    apps_installed=""
    if command -v docker >/dev/null 2>&1; then
        apps_installed="${apps_installed}Docker, "
    fi
    if [ -d "$HOME/RetroPie-Setup" ]; then
        apps_installed="${apps_installed}RetroPie, "
    fi
    if command -v kodi >/dev/null 2>&1; then
        apps_installed="${apps_installed}Kodi, "
    fi
    
    if [ -n "$apps_installed" ]; then
        echo "✅ APPLICATIONS INSTALLED:"
        echo "   ${apps_installed%, }"
        echo ""
        echo "🎯 READY TO REBOOT!"
        echo "All software is installed and will benefit from hardware optimizations."
    else
        echo "ℹ️  No applications detected yet."
        echo "You can install applications first, then reboot, or reboot now."
    fi
    
    echo ""
    read -p "Reboot now to activate hardware changes? (y/N): " choice
    case "${choice,,}" in
        y|yes)
            log_info "Rebooting to activate hardware optimizations..."
            sleep 2
            sudo reboot
            ;;
        *)
            echo ""
            echo "Reboot deferred. Run this script again when ready:"
            echo "  ./reboot-when-ready.sh"
            echo ""
            echo "Or manually reboot:"
            echo "  sudo reboot"
            ;;
    esac
else
    echo "ℹ️  NO HARDWARE CHANGES DETECTED"
    echo ""
    echo "No boot configuration changes were found."
    echo "A reboot is not required unless you've installed applications"
    echo "that specifically request it."
    echo ""
    echo "If you want to reboot anyway:"
    echo "  sudo reboot"
fi

echo ""
echo "=============================================="
