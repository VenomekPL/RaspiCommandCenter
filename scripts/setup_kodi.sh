#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Find RetroPie Kodi installation
find_retropie_kodi() {
    echo "Locating RetroPie Kodi installation..."
    
    # Common RetroPie Kodi locations
    local kodi_locations=(
        "/opt/retropie/ports/kodi"
        "/home/$USER/RetroPie/roms/ports/kodi"
        "/usr/bin/kodi"
        "/usr/local/bin/kodi"
    )
    
    for location in "${kodi_locations[@]}"; do
        if [[ -x "$location/kodi" ]] || [[ -x "$location" ]]; then
            echo "✓ Found Kodi at: $location"
            KODI_PATH="$location"
            return 0
        fi
    done
    
    # Try to find Kodi binary in PATH
    if command -v kodi >/dev/null 2>&1; then
        KODI_PATH=$(which kodi)
        echo "✓ Found Kodi in PATH: $KODI_PATH"
        return 0
    fi
    
    echo "ERROR: Kodi installation not found"
    echo "Make sure RetroPie with Kodi port is installed first"
    exit 1
}

# Locate Kodi configuration directory
find_kodi_config() {
    echo "Locating Kodi configuration directory..."
    
    # Common Kodi config locations
    local config_locations=(
        "$HOME/.kodi"
        "$HOME/.xbmc"
        "/home/$USER/.kodi"
        "/opt/retropie/configs/ports/kodi"
    )
    
    for location in "${config_locations[@]}"; do
        if [[ -d "$location" ]]; then
            echo "✓ Found Kodi config at: $location"
            KODI_CONFIG_DIR="$location"
            return 0
        fi
    done
    
    # Create default Kodi config directory
    KODI_CONFIG_DIR="$HOME/.kodi"
    mkdir -p "$KODI_CONFIG_DIR"
    echo "✓ Created Kodi config directory: $KODI_CONFIG_DIR"
}

# Configure media libraries and folder mapping
configure_media_libraries() {
    echo "Configuring media libraries..."
    
    mkdir -p "$KODI_CONFIG_DIR/userdata"
    
    # Create sources.xml for media library paths
    cat > "$KODI_CONFIG_DIR/userdata/sources.xml" << EOF
<sources>
    <programs>
        <default pathversion="1"></default>
    </programs>
    <video>
        <default pathversion="1"></default>
        <source>
            <name>Movies</name>
            <path pathversion="1">$HOME/Videos/Movies/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>TV Shows</name>
            <path pathversion="1">$HOME/Videos/TVShows/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Home Videos</name>
            <path pathversion="1">$HOME/Videos/</path>
            <allowsharing>true</allowsharing>
        </source>
    </video>
    <music>
        <default pathversion="1"></default>
        <source>
            <name>Music</name>
            <path pathversion="1">$HOME/Music/</path>
            <allowsharing>true</allowsharing>
        </source>
    </music>
    <pictures>
        <default pathversion="1"></default>
        <source>
            <name>Pictures</name>
            <path pathversion="1">$HOME/Pictures/</path>
            <allowsharing>true</allowsharing>
        </source>
    </pictures>
    <files>
        <default pathversion="1"></default>
        <source>
            <name>Home</name>
            <path pathversion="1">$HOME/</path>
            <allowsharing>true</allowsharing>
        </source>
    </files>
</sources>
EOF
    
    # Create media directories
    local media_dirs=(
        "$HOME/Videos/Movies"
        "$HOME/Videos/TVShows"
        "$HOME/Music"
        "$HOME/Pictures"
    )
    
    for dir in "${media_dirs[@]}"; do
        mkdir -p "$dir"
        echo "✓ Created media directory: $dir"
    done
    
    echo "✓ Media libraries configured"
}

# Configure Kodi for optimal performance and controller support
configure_kodi_settings() {
    echo "Configuring Kodi settings..."
    
    mkdir -p "$KODI_CONFIG_DIR/userdata"
    
    # Advanced settings for performance
    cat > "$KODI_CONFIG_DIR/userdata/advancedsettings.xml" << 'EOF'
<advancedsettings>
    <video>
        <playcountminimumpercent>90</playcountminimumpercent>
        <ignoresecondsatstart>240</ignoresecondsatstart>
        <ignorepercentatend>8</ignorepercentatend>
    </video>
    <network>
        <curlclienttimeout>30</curlclienttimeout>
        <curllowspeedtime>20</curllowspeedtime>
        <curlretries>2</curlretries>
    </network>
    <cache>
        <memorysize>104857600</memorysize>
        <buffermode>1</buffermode>
        <readbufferfactor>4.0</readbufferfactor>
    </cache>
    <gui>
        <algorithmdirtyregions>3</algorithmdirtyregions>
        <nofliptimeout>0</nofliptimeout>
    </gui>
</advancedsettings>
EOF
    
    # Kodi settings for controllers and performance
    cat > "$KODI_CONFIG_DIR/userdata/guisettings.xml" << 'EOF'
<settings version="2">
    <setting id="audiocds.autoaction">0</setting>
    <setting id="audiooutput.audiodevice">PI:Analogue</setting>
    <setting id="audiooutput.channels">2</setting>
    <setting id="audiooutput.config">2</setting>
    <setting id="input.enablejoystick">true</setting>
    <setting id="input.peripherals">true</setting>
    <setting id="lookandfeel.enablerssfeeds">false</setting>
    <setting id="musiclibrary.updateonstartup">true</setting>
    <setting id="screensaver.mode">screensaver.xbmc.builtin.black</setting>
    <setting id="services.webserver">true</setting>
    <setting id="services.webserverport">8080</setting>
    <setting id="services.zeroconf">true</setting>
    <setting id="system.playlistspath">$HOME/.kodi/userdata/playlists/</setting>
    <setting id="videolibrary.updateonstartup">true</setting>
    <setting id="videoplayer.adjustrefreshrate">0</setting>
    <setting id="videoplayer.useamcodec">true</setting>
    <setting id="videoplayer.usemmal">true</setting>
</settings>
EOF
    
    echo "✓ Kodi performance and controller settings configured"
}

# Install Elementum plugin for torrents
install_elementum_plugin() {
    echo "Installing Elementum plugin..."
    
    local addons_dir="$KODI_CONFIG_DIR/addons"
    mkdir -p "$addons_dir"
    
    # Download Elementum repository
    local elementum_repo_url="https://github.com/elgatito/plugin.video.elementum/releases/latest/download/repository.elementum.zip"
    local temp_zip="/tmp/repository.elementum.zip"
    
    echo "Downloading Elementum repository..."
    if curl -L -o "$temp_zip" "$elementum_repo_url" 2>/dev/null; then
        unzip -q "$temp_zip" -d "$addons_dir/"
        rm "$temp_zip"
        echo "✓ Elementum repository installed"
    else
        echo "✗ Failed to download Elementum repository"
        echo "You can install it manually through Kodi's addon manager"
    fi
    
    # Create addon configuration
    local elementum_config_dir="$KODI_CONFIG_DIR/userdata/addon_data/plugin.video.elementum"
    mkdir -p "$elementum_config_dir"
    
    cat > "$elementum_config_dir/settings.xml" << EOF
<settings>
    <setting id="download_path" value="$HOME/Downloads/Torrents" />
    <setting id="library_enabled" value="true" />
    <setting id="auto_library_update" value="true" />
    <setting id="download_storage" value="0" />
</settings>
EOF
    
    # Create downloads directory
    mkdir -p "$HOME/Downloads/Torrents"
    
    echo "✓ Elementum plugin configured"
}

main() {
    local auto_mode=false
    
    # Check for --auto flag
    if [[ "${1:-}" == "--auto" ]]; then
        auto_mode=true
    fi
    
    if [[ "$auto_mode" == "false" ]]; then
        echo "=== Kodi Configuration ==="
        echo ""
        echo "This will configure the existing RetroPie Kodi installation:"
        echo "• Locate existing Kodi installation"
        echo "• Configure media libraries and folder mapping"
        echo "• Enable controller support"
        echo "• Optimize for HD video playback"
        echo "• Set up auto-scan and discovery"
        echo "• Install Elementum plugin for torrents"
        echo ""
        
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Configuration cancelled"
            exit 0
        fi
    else
        echo "Configuring Kodi automatically..."
    fi
    
    find_retropie_kodi
    find_kodi_config
    configure_media_libraries
    configure_kodi_settings
    install_elementum_plugin
    
    echo ""
    echo "=== Kodi Configuration Complete ==="
    echo "✓ Kodi found and configured at: $KODI_PATH"
    echo "✓ Media libraries configured for user: $USER"
    echo "✓ Controller support enabled"
    echo "✓ Elementum plugin installed"
    
    if [[ "$auto_mode" == "false" ]]; then
        echo ""
        echo "Access Kodi:"
        echo "• From EmulationStation: Navigate to Ports → Kodi (RetroPie integration)"
        echo "• Web interface: http://$(hostname -I | awk '{print $1}'):8080"
        echo "• Direct command: $KODI_PATH"
        echo ""
        echo "Media directories created:"
        echo "• Movies: $HOME/Videos/Movies/"
        echo "• TV Shows: $HOME/Videos/TVShows/"
        echo "• Music: $HOME/Music/"
        echo "• Pictures: $HOME/Pictures/"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
