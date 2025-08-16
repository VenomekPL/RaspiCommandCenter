#!/bin/bash

set -euo pipefail

setup_homeassistant_docker() {
    echo "=== Setting up Home Assistant with Docker ==="
    
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        echo "Starting Docker service..."
        systemctl start docker
        systemctl enable docker
    fi
    
    # Stop any existing Home Assistant container
    if docker ps -a --format "table {{.Names}}" | grep -q "^homeassistant$"; then
        echo "Stopping existing Home Assistant container..."
        docker stop homeassistant >/dev/null 2>&1 || true
        docker rm homeassistant >/dev/null 2>&1 || true
    fi
    
    # Create Home Assistant config directory
    local config_dir="/opt/homeassistant"
    echo "Creating config directory: $config_dir"
    mkdir -p "$config_dir"
    
    # Set proper permissions
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "${SUDO_USER}:${SUDO_USER}" "$config_dir"
    fi
    
    # Get timezone
    local timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
    echo "Using timezone: $timezone"
    
    # Pull Home Assistant image
    echo "Pulling Home Assistant Docker image..."
    docker pull ghcr.io/home-assistant/home-assistant:stable
    
    # Run Home Assistant container
    echo "Starting Home Assistant container..."
    docker run -d \
        --name homeassistant \
        --privileged \
        --restart=unless-stopped \
        -e TZ="$timezone" \
        -v "$config_dir:/config" \
        -v /run/dbus:/run/dbus:ro \
        --network=host \
        ghcr.io/home-assistant/home-assistant:stable
    
    # Wait for container to be ready
    echo "Waiting for Home Assistant to start..."
    sleep 30
    
    # Check if container is running
    if docker ps --format "table {{.Names}}" | grep -q "^homeassistant$"; then
        echo "✓ Home Assistant container is running"
        
        # Get IP address for user
        local ip_address=$(hostname -I | awk '{print $1}')
        echo ""
        echo "=== Home Assistant Setup Complete ==="
        echo "Access Home Assistant at: http://$ip_address:8123"
        echo "Config directory: $config_dir"
        echo ""
        echo "Initial setup may take a few minutes as Home Assistant initializes."
        echo "Create your admin account when you first access the web interface."
    else
        echo "✗ Failed to start Home Assistant container"
        echo "Check logs with: docker logs homeassistant"
        return 1
    fi
}

main() {
    echo "=== Home Assistant Docker Installation ==="
    echo ""
    echo "This will install Home Assistant using the official Docker container:"
    echo "• Clean, simple Docker installation"
    echo "• No complex dependencies or network configuration"
    echo "• Official Home Assistant image"
    echo "• Automatic restart on reboot"
    echo ""
    
    setup_homeassistant_docker
    
    echo "=== Home Assistant installation completed ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
