#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "${SCRIPT_DIR}/../utils/common.sh"

update_system() {
    echo "Updating package lists..."
    apt update
    apt autoclean
}

install_from_requirements() {
    echo "Installing packages from requirements.txt..."
    
    local requirements_file="${PROJECT_DIR}/requirements.txt"
    if [[ ! -f "$requirements_file" ]]; then
        echo "ERROR: requirements.txt not found"
        exit 1
    fi
    
    # Read packages from requirements.txt and install
    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue
        
        if apt install -y "$package" >/dev/null 2>&1; then
            echo "✓ $package"
        else
            echo "✗ $package (failed)"
        fi
    done < "$requirements_file"
}

install_media_libraries() {
    echo "Installing media processing libraries..."
    
    local media_libs=(
        "ffmpeg"
        "libavformat-dev"
        "libavcodec-dev"
        "libavdevice-dev"
        "libavfilter-dev"
        "libavutil-dev"
        "libswscale-dev"
        "libswresample-dev"
        "libjpeg-dev"
        "libpng-dev"
        "libtiff-dev"
        "libwebp-dev"
        "alsa-utils"
        "pulseaudio"
        "pulseaudio-utils"
    )
    
    for package in "${media_libs[@]}"; do
        if apt install -y "$package" >/dev/null 2>&1; then
            echo "✓ $package"
        else
            echo "✗ $package (failed)"
        fi
    done
}

install_docker() {
    echo "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        echo "Docker already installed"
        return 0
    fi
    
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh >/dev/null 2>&1
    rm get-docker.sh
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
    fi
    
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
}

main() {
    echo "=== Installing Dependencies ==="
    
    update_system
    install_from_requirements
    install_media_libraries
    install_docker
    
    echo "=== Dependencies installation completed ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
