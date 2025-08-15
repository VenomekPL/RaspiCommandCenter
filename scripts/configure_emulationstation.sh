#!/bin/bash

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration
RETROPIE_CONFIG_DIR="$HOME/.emulationstation"
RETROPIE_ROMS_DIR="$HOME/ROMs"

install_all_emulators() {
    echo "Installing comprehensive emulator collection..."
    
    cd "$HOME/RetroPie-Setup"
    
    # Core emulators - install automatically
    local core_emulators=(
        # Essential retro consoles
        "lr-nestopia"           # Nintendo NES
        "lr-snes9x"            # Super Nintendo
        "lr-genesis-plus-gx"   # Sega Genesis/Master System
        "lr-gambatte"          # Game Boy/Game Boy Color
        "lr-mgba"              # Game Boy Advance
        "lr-mupen64plus-next"  # Nintendo 64
        "lr-beetle-psx-hw"     # PlayStation 1
        "lr-ppsspp"            # PlayStation Portable
        "lr-flycast"           # Dreamcast
        "lr-mame2003-plus"     # Arcade (MAME 2003 Plus)
        "lr-fbalpha2012"       # Final Burn Alpha
        "lr-stella2014"        # Atari 2600
        "lr-prosystem"         # Atari 7800
        "lr-handy"             # Atari Lynx
        "lr-o2em"              # Odyssey 2
        "lr-vecx"              # Vectrex
        "lr-cap32"             # Amstrad CPC
        "lr-vice"              # Commodore 64
        "lr-bluemsx"           # MSX
        "lr-fuse"              # ZX Spectrum
    )
    
    echo "Installing core emulators..."
    for emulator in "${core_emulators[@]}"; do
        echo "Installing $emulator..."
        sudo ./retropie_setup.sh "$emulator" autoinstall >/dev/null 2>&1 || echo "Failed: $emulator"
    done
    
    # Advanced emulators
    local advanced_emulators=(
        "lr-beetle-saturn"     # Sega Saturn
        "lr-beetle-supergrafx" # PC Engine SuperGrafx
        "lr-desmume"          # Nintendo DS
        "lr-beetle-wswan"     # WonderSwan
        "lr-picodrive"        # Sega 32X/CD
        "lr-kronos"           # Sega Saturn (alternative)
        "lr-puae"             # Amiga
        "lr-mame2016"         # MAME 2016
        "scummvm"             # Adventure games
        "dosbox"              # DOS games
    )
    
    echo "Installing advanced emulators..."
    for emulator in "${advanced_emulators[@]}"; do
        echo "Installing $emulator..."
        sudo ./retropie_setup.sh "$emulator" autoinstall >/dev/null 2>&1 || echo "Failed: $emulator"
    done
    
    echo "✓ Emulator installation completed"
}

create_comprehensive_rom_structure() {
    echo "Creating comprehensive ROM directory structure..."
    
    mkdir -p "$RETROPIE_ROMS_DIR"
    
    # ROM systems with proper names
    declare -A rom_systems=(
        # Nintendo Systems
        ["nes"]="Nintendo Entertainment System"
        ["snes"]="Super Nintendo Entertainment System"
        ["n64"]="Nintendo 64"
        ["gb"]="Game Boy"
        ["gbc"]="Game Boy Color"
        ["gba"]="Game Boy Advance"
        ["nds"]="Nintendo DS"
        ["fds"]="Famicom Disk System"
        
        # Sega Systems
        ["mastersystem"]="Sega Master System"
        ["genesis"]="Sega Genesis/Mega Drive"
        ["sega32x"]="Sega 32X"
        ["segacd"]="Sega CD"
        ["saturn"]="Sega Saturn"
        ["dreamcast"]="Sega Dreamcast"
        ["gamegear"]="Sega Game Gear"
        
        # Sony Systems
        ["psx"]="Sony PlayStation"
        ["psp"]="PlayStation Portable"
        
        # Atari Systems
        ["atari2600"]="Atari 2600"
        ["atari5200"]="Atari 5200"
        ["atari7800"]="Atari 7800"
        ["atarilynx"]="Atari Lynx"
        ["atarijaguar"]="Atari Jaguar"
        
        # Arcade Systems
        ["arcade"]="Arcade"
        ["mame-libretro"]="MAME"
        ["fba"]="Final Burn Alpha"
        ["neogeo"]="Neo Geo"
        
        # Computer Systems
        ["amiga"]="Commodore Amiga"
        ["c64"]="Commodore 64"
        ["amstradcpc"]="Amstrad CPC"
        ["msx"]="MSX"
        ["zxspectrum"]="ZX Spectrum"
        
        # Other Systems
        ["3do"]="3DO"
        ["coleco"]="ColecoVision"
        ["intellivision"]="Intellivision"
        ["odyssey2"]="Odyssey 2"
        ["vectrex"]="Vectrex"
        ["wonderswan"]="WonderSwan"
        ["ngp"]="Neo Geo Pocket"
        ["pcengine"]="PC Engine/TurboGrafx-16"
        
        # Special Categories
        ["ports"]="Ports"
        ["scummvm"]="ScummVM"
        ["kodi"]="Kodi"
    )
    
    # Create directories and info files
    for system in "${!rom_systems[@]}"; do
        local system_dir="$RETROPIE_ROMS_DIR/$system"
        mkdir -p "$system_dir"
        
        # Create README with system info
        cat > "$system_dir/README.txt" << EOF
${rom_systems[$system]} ROMs

Place your ${rom_systems[$system]} ROM files in this directory.

Supported file formats vary by system.
Check RetroPie documentation for specific formats.

Directory: $system
EOF
    done
    
    echo "✓ ROM structure created with $(( ${#rom_systems[@]} )) systems"
}

create_controller_mappings() {
    echo "Creating comprehensive controller mappings..."
    
    mkdir -p "$RETROPIE_CONFIG_DIR/inputconfigs"
    
    # Xbox Wireless Controller (Series X/S)
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Xbox Wireless Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Xbox Wireless Controller" deviceGUID="030000005e040000e002000000007200">
    <input name="a" type="button" id="0" value="1" />
    <input name="b" type="button" id="1" value="1" />
    <input name="x" type="button" id="2" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="4" value="1" />
    <input name="guide" type="button" id="5" value="1" />
    <input name="start" type="button" id="6" value="1" />
    <input name="leftstick" type="button" id="7" value="1" />
    <input name="rightstick" type="button" id="8" value="1" />
    <input name="leftshoulder" type="button" id="9" value="1" />
    <input name="rightshoulder" type="button" id="10" value="1" />
    <input name="dpup" type="button" id="11" value="1" />
    <input name="dpdown" type="button" id="12" value="1" />
    <input name="dpleft" type="button" id="13" value="1" />
    <input name="dpright" type="button" id="14" value="1" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF
    
    # PlayStation DualSense Controller
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Wireless Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Wireless Controller" deviceGUID="030000004c050000cc09000000810000">
    <input name="a" type="button" id="1" value="1" />
    <input name="b" type="button" id="2" value="1" />
    <input name="x" type="button" id="0" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="8" value="1" />
    <input name="guide" type="button" id="12" value="1" />
    <input name="start" type="button" id="9" value="1" />
    <input name="leftstick" type="button" id="10" value="1" />
    <input name="rightstick" type="button" id="11" value="1" />
    <input name="leftshoulder" type="button" id="4" value="1" />
    <input name="rightshoulder" type="button" id="5" value="1" />
    <input name="dpup" type="hat" id="0" value="1" />
    <input name="dpdown" type="hat" id="0" value="4" />
    <input name="dpleft" type="hat" id="0" value="8" />
    <input name="dpright" type="hat" id="0" value="2" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="5" value="1" />
    <input name="lefttrigger" type="axis" id="3" value="1" />
    <input name="righttrigger" type="axis" id="4" value="1" />
</inputConfig>
EOF
    
    # Nintendo Switch Pro Controller
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/Pro Controller.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="Pro Controller" deviceGUID="030000007e0500000920000000000000">
    <input name="a" type="button" id="0" value="1" />
    <input name="b" type="button" id="1" value="1" />
    <input name="x" type="button" id="2" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="4" value="1" />
    <input name="guide" type="button" id="5" value="1" />
    <input name="start" type="button" id="6" value="1" />
    <input name="leftstick" type="button" id="7" value="1" />
    <input name="rightstick" type="button" id="8" value="1" />
    <input name="leftshoulder" type="button" id="9" value="1" />
    <input name="rightshoulder" type="button" id="10" value="1" />
    <input name="dpup" type="hat" id="0" value="1" />
    <input name="dpdown" type="hat" id="0" value="4" />
    <input name="dpleft" type="hat" id="0" value="8" />
    <input name="dpright" type="hat" id="0" value="2" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF
    
    # 8BitDo SN30 Pro (popular retro controller)
    cat > "$RETROPIE_CONFIG_DIR/inputconfigs/8BitDo SN30 Pro.cfg" << 'EOF'
<?xml version="1.0"?>
<inputConfig type="joystick" deviceName="8BitDo SN30 Pro" deviceGUID="030000003512000020ab000000010000">
    <input name="a" type="button" id="1" value="1" />
    <input name="b" type="button" id="0" value="1" />
    <input name="x" type="button" id="4" value="1" />
    <input name="y" type="button" id="3" value="1" />
    <input name="back" type="button" id="10" value="1" />
    <input name="guide" type="button" id="2" value="1" />
    <input name="start" type="button" id="11" value="1" />
    <input name="leftstick" type="button" id="13" value="1" />
    <input name="rightstick" type="button" id="14" value="1" />
    <input name="leftshoulder" type="button" id="6" value="1" />
    <input name="rightshoulder" type="button" id="7" value="1" />
    <input name="dpup" type="hat" id="0" value="1" />
    <input name="dpdown" type="hat" id="0" value="4" />
    <input name="dpleft" type="hat" id="0" value="8" />
    <input name="dpright" type="hat" id="0" value="2" />
    <input name="leftx" type="axis" id="0" value="1" />
    <input name="lefty" type="axis" id="1" value="1" />
    <input name="rightx" type="axis" id="2" value="1" />
    <input name="righty" type="axis" id="3" value="1" />
    <input name="lefttrigger" type="axis" id="4" value="1" />
    <input name="righttrigger" type="axis" id="5" value="1" />
</inputConfig>
EOF
    
    echo "✓ Controller mappings created for Xbox, PlayStation, Switch Pro, and 8BitDo controllers"
}

setup_controller_autodiscovery() {
    echo "Setting up controller auto-discovery..."
    
    # Create udev rules for automatic controller permissions
    sudo tee /etc/udev/rules.d/99-emulationstation-controllers.rules > /dev/null << 'EOF'
# PlayStation controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="054c", MODE="0666"
# Xbox controllers  
SUBSYSTEM=="input", ATTRS{idVendor}=="045e", MODE="0666"
# Nintendo controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="057e", MODE="0666"
# 8BitDo controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="2dc8", MODE="0666"
# Generic USB controllers
SUBSYSTEM=="input", ATTRS{idVendor}=="0079", MODE="0666"
EOF
    
    sudo udevadm control --reload-rules
    
    # Configure Bluetooth for gaming controllers
    sudo mkdir -p /etc/bluetooth/main.conf.d
    sudo tee /etc/bluetooth/main.conf.d/gaming.conf > /dev/null << 'EOF'
[General]
Class=0x000100
DiscoverableTimeout=0
PairableTimeout=0

[Policy]
AutoEnable=true
EOF
    
    echo "✓ Controller auto-discovery configured"
}

install_popular_themes() {
    echo "Installing popular EmulationStation themes..."
    
    local theme_dir="$RETROPIE_CONFIG_DIR/themes"
    mkdir -p "$theme_dir"
    
    # Popular themes
    declare -A themes=(
        ["carbon"]="https://github.com/RetroPie/es-theme-carbon.git"
        ["simple"]="https://github.com/RetroPie/es-theme-simple.git"
        ["pixel"]="https://github.com/RetroPie/es-theme-pixel.git"
        ["clean-look"]="https://github.com/RetroPie/es-theme-clean-look.git"
        ["switchOS"]="https://github.com/lilbud/es-theme-switchOS.git"
    )
    
    for theme_name in "${!themes[@]}"; do
        local theme_url="${themes[$theme_name]}"
        
        if [ ! -d "$theme_dir/$theme_name" ]; then
            echo "Installing theme: $theme_name"
            if git clone --depth=1 "$theme_url" "$theme_dir/$theme_name" >/dev/null 2>&1; then
                echo "✓ Theme $theme_name installed"
            else
                echo "✗ Failed to install theme $theme_name"
            fi
        else
            echo "Theme $theme_name already exists"
        fi
    done
    
    echo "✓ Theme installation completed"
}

configure_emulationstation_settings() {
    echo "Configuring EmulationStation settings..."
    
    mkdir -p "$RETROPIE_CONFIG_DIR"
    
    # EmulationStation settings for optimal performance
    cat > "$RETROPIE_CONFIG_DIR/es_settings.cfg" << 'EOF'
<?xml version="1.0"?>
<config>
    <int name="ScreenSaverTime" value="300000" />
    <bool name="DrawFramerate" value="false" />
    <bool name="ShowHelpPrompts" value="true" />
    <bool name="ScrapeRatings" value="true" />
    <bool name="IgnoreGamelist" value="false" />
    <bool name="HideConsole" value="false" />
    <string name="PowerSaverMode" value="enhanced" />
    <string name="TransitionStyle" value="fade" />
    <int name="MaxVRAM" value="512" />
    <string name="ThemeSet" value="carbon" />
    <bool name="ParseGamelistOnly" value="false" />
    <bool name="ShowExit" value="true" />
    <string name="ExitButtonCombo" value="start+select" />
</config>
EOF
    
    echo "✓ EmulationStation settings configured"
}

main() {
    local auto_mode=false
    
    # Check for --auto flag
    if [[ "${1:-}" == "--auto" ]]; then
        auto_mode=true
    fi
    
    if [[ "$auto_mode" == "false" ]]; then
        echo "=== EmulationStation Configuration ==="
        echo ""
        echo "This will configure:"
        echo "• Install all major emulators"
        echo "• Create comprehensive ROM structure" 
        echo "• Set up controller mappings and auto-discovery"
        echo "• Install popular themes"
        echo "• Configure optimal settings"
        echo ""
        
        read -p "Continue with configuration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Configuration cancelled"
            exit 0
        fi
    else
        echo "Running EmulationStation configuration automatically..."
    fi
    
    if [ ! -d "$HOME/RetroPie-Setup" ]; then
        echo "ERROR: RetroPie-Setup not found. Run basic setup first."
        exit 1
    fi
    
    install_all_emulators
    echo ""
    
    create_comprehensive_rom_structure  
    echo ""
    
    create_controller_mappings
    echo ""
    
    setup_controller_autodiscovery
    echo ""
    
    install_popular_themes
    echo ""
    
    configure_emulationstation_settings
    
    echo ""
    echo "=== EmulationStation Configuration Complete ==="
    echo "✓ $(ls "$RETROPIE_ROMS_DIR" 2>/dev/null | wc -l) ROM directories created"
    echo "✓ 4 controller types pre-configured"
    echo "✓ 5 themes installed"
    echo "✓ Auto-discovery enabled"
    
    if [[ "$auto_mode" == "false" ]]; then
        echo ""
        echo "Next steps:"
        echo "1. Add ROM files to ~/ROMs/[system]/ directories"
        echo "2. Run 'emulationstation' to start gaming"
        echo "3. Controllers will be auto-detected when connected"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
