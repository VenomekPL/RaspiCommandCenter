#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

main() {
    echo "=== Phase 2: Installing Applications ==="
    
    echo "Installing Home Assistant (Docker)..."
    if [ -x "${SCRIPT_DIR}/setup_homeassistant_docker.sh" ]; then
        "${SCRIPT_DIR}/setup_homeassistant_docker.sh"
        echo "✓ Home Assistant (Docker) installed"
    else
        echo "ERROR: Home Assistant Docker setup script not found"
        exit 1
    fi
    
    echo ""
    echo "Installing EmulationStation (as user)..."
    if [ -x "${SCRIPT_DIR}/setup_emulationstation.sh" ]; then
        # Run as the original user, not root
        if [[ -n "${SUDO_USER:-}" ]]; then
            sudo -u "$SUDO_USER" "${SCRIPT_DIR}/setup_emulationstation.sh"
            echo "✓ EmulationStation installed"
        else
            echo "ERROR: No SUDO_USER found - cannot run EmulationStation setup as non-root user"
            exit 1
        fi
    else
        echo "ERROR: EmulationStation setup script not found"
        exit 1
    fi
    
    echo ""
    echo "Installing NAS File Server..."
    if [ -x "${SCRIPT_DIR}/setup_nas_fileserver.sh" ]; then
        "${SCRIPT_DIR}/setup_nas_fileserver.sh" --auto
        echo "✓ NAS File Server installed"
    else
        echo "WARNING: NAS File Server setup script not found - skipping"
    fi
    
    echo ""
    echo "Phase 2 completed successfully!"
    echo "• Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
    echo "• EmulationStation: Run 'emulationstation' command"
    echo "• NAS Shares: \\\\$(hostname -I | awk '{print $1}') (Videos, Music, Pictures, ROMs, Downloads)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
