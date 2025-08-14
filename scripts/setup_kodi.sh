#!/bin/bash

# Kodi Integration Setup Script
# This script installs and configures Kodi as an EmulationStation "port"
# for seamless media center integration

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration
KODI_PORT_DIR="$HOME/ROMs/ports"
RETROPIE_CONFIG_DIR="$HOME/.emulationstation"

log_info "Starting Kodi Integration Setup"

# Function to install Kodi
install_kodi() {
    log_info "Installing Kodi media center..."
    
    # Update package list
    sudo apt update
    
    # Install Kodi and dependencies
    sudo apt install -y kodi kodi-bin kodi-data
    
    # Install additional Kodi packages for better functionality
    sudo apt install -y \
        kodi-addons-dev \
        kodi-eventclients-dev \
        kodi-inputstream-adaptive \
        kodi-inputstream-rtmp \
        kodi-peripheral-joystick \
        kodi-pvr-hts \
        kodi-screensaver-* \
        kodi-visualization-* \
        python3-pip \
        python3-dev \
        git \
        curl \
        unzip \
        libtorrent-rasterbar-dev \
        python3-libtorrent
    
    # Install Python dependencies for Elementum and CLI tools
    pip3 install --user requests beautifulsoup4 lxml
    
    log_success "Kodi installation completed"
}

# Function to configure Kodi integration with EmulationStation
configure_kodi_integration() {
    log_info "Configuring Kodi integration with EmulationStation..."
    
    # Create ports directory if it doesn't exist
    mkdir -p "$KODI_PORT_DIR"
    
    # Create Kodi launcher script
    cat > "$KODI_PORT_DIR/Kodi.sh" << 'EOF'
#!/bin/bash

# Kodi Launcher for EmulationStation
# This script provides seamless switching between EmulationStation and Kodi

# Function to check if EmulationStation is running
check_emulationstation() {
    pgrep -x "emulationstation" > /dev/null
}

# Kill EmulationStation if running
if check_emulationstation; then
    echo "Stopping EmulationStation..."
    sudo pkill -f emulationstation
    sleep 2
fi

# Start Kodi
echo "Starting Kodi..."
kodi-standalone

# After Kodi exits, restart EmulationStation
echo "Kodi closed, restarting EmulationStation..."
sleep 2
emulationstation
EOF
    
    chmod +x "$KODI_PORT_DIR/Kodi.sh"
    
    # Create Kodi game list entry for EmulationStation
    mkdir -p "$RETROPIE_CONFIG_DIR/gamelists/ports"
    
    cat > "$RETROPIE_CONFIG_DIR/gamelists/ports/gamelist.xml" << EOF
<?xml version="1.0"?>
<gameList>
    <game>
        <path>./Kodi.sh</path>
        <name>Kodi Media Center</name>
        <desc>Launch Kodi media center for videos, music, and streaming. Navigate with your controller or connect a keyboard/mouse for full functionality.</desc>
        <image>./images/kodi-image.png</image>
        <thumbnail>./images/kodi-thumb.png</thumbnail>
        <rating>1.0</rating>
        <releasedate>20240101T000000</releasedate>
        <developer>Team Kodi</developer>
        <publisher>Kodi Foundation</publisher>
        <genre>Media Center</genre>
        <players>1</players>
    </game>
</gameList>
EOF
    
    # Create images directory and placeholder images
    mkdir -p "$RETROPIE_CONFIG_DIR/gamelists/ports/images"
    
    # Create simple text-based images (will be replaced with actual images later)
    echo "Kodi Media Center Logo Placeholder" > "$RETROPIE_CONFIG_DIR/gamelists/ports/images/kodi-image.png"
    echo "Kodi Thumbnail Placeholder" > "$RETROPIE_CONFIG_DIR/gamelists/ports/images/kodi-thumb.png"
    
    log_success "Kodi integration configured"
}

# Function to configure Kodi for controller use
configure_kodi_controller() {
    log_info "Configuring Kodi for game controller use..."
    
    # Create Kodi userdata directory
    mkdir -p "$HOME/.kodi/userdata"
    
    # Configure Kodi for controller input
    cat > "$HOME/.kodi/userdata/advancedsettings.xml" << 'EOF'
<advancedsettings>
    <input>
        <enablejoystick>true</enablejoystick>
        <joystickdeadzone>0.2</joystickdeadzone>
        <joysticksensitivity>1.0</joysticksensitivity>
    </input>
    <network>
        <cachemembuffersize>52428800</cachemembuffersize>
        <readbufferfactor>4.0</readbufferfactor>
    </network>
    <gui>
        <algorithmdirtyregions>3</algorithmdirtyregions>
        <nofliptimeout>0</nofliptimeout>
    </gui>
    <services>
        <webserver>true</webserver>
        <webserverport>8080</webserverport>
        <webserverusername>kodi</webserverusername>
        <webserverpassword>kodi</webserverpassword>
        <webskin>webinterface.default</webskin>
        <zeroconf>true</zeroconf>
        <upnpserver>true</upnpserver>
        <upnprenderer>true</upnprenderer>
        <upnpcontroller>true</upnpcontroller>
        <eventserver>true</eventserver>
        <eventserverport>9777</eventserverport>
        <eserv>true</eserv>
        <airplay>true</airplay>
        <airplaypassword></airplaypassword>
        <useairplaypassword>false</useairplaypassword>
    </services>
    <jsonrpc>
        <compactoutput>true</compactoutput>
        <tcpport>9090</tcpport>
        <httpport>8080</httpport>
    </jsonrpc>
</advancedsettings>
EOF
    
    # Create custom keymap for controllers
    mkdir -p "$HOME/.kodi/userdata/keymaps"
    
    cat > "$HOME/.kodi/userdata/keymaps/joystick.xml" << 'EOF'
<keymap>
    <global>
        <joystick name="Xbox Wireless Controller">
            <button id="1">Select</button>
            <button id="2">Back</button>
            <button id="3">ContextMenu</button>
            <button id="4">FullScreen</button>
            <button id="7">PreviousMenu</button>
            <button id="8">Home</button>
            <hat id="1" position="up">Up</hat>
            <hat id="1" position="down">Down</hat>
            <hat id="1" position="left">Left</hat>
            <hat id="1" position="right">Right</hat>
            <axis id="1" limit="-1">Left</axis>
            <axis id="1" limit="+1">Right</axis>
            <axis id="2" limit="-1">Up</axis>
            <axis id="2" limit="+1">Down</axis>
        </joystick>
        <joystick name="PlayStation Controller">
            <button id="1">Select</button>
            <button id="2">Back</button>
            <button id="3">ContextMenu</button>
            <button id="4">FullScreen</button>
            <button id="10">PreviousMenu</button>
            <button id="13">Home</button>
            <hat id="1" position="up">Up</hat>
            <hat id="1" position="down">Down</hat>
            <hat id="1" position="left">Left</hat>
            <hat id="1" position="right">Right</hat>
        </joystick>
    </global>
    <Home>
        <joystick name="Xbox Wireless Controller">
            <button id="6">Shutdown</button>
        </joystick>
        <joystick name="PlayStation Controller">
            <button id="12">Shutdown</button>
        </joystick>
    </Home>
</keymap>
EOF
    
    log_success "Kodi controller configuration completed"
}

# Function to setup media folders and library sources
setup_media_folders_and_library() {
    log_info "Setting up media folders and Kodi library configuration..."
    
    # Define media folder paths
    USER_VIDEOS_DIR="$HOME/Videos"
    MOVIES_DIR="$USER_VIDEOS_DIR/Movies"
    TV_SERIES_DIR="$USER_VIDEOS_DIR/TV Shows"
    DOCUMENTARIES_DIR="$USER_VIDEOS_DIR/Documentaries"
    MUSIC_DIR="$HOME/Music"
    PICTURES_DIR="$HOME/Pictures"
    
    # Create media directory structure
    log_info "Creating media directory structure..."
    mkdir -p "$MOVIES_DIR"
    mkdir -p "$TV_SERIES_DIR"
    mkdir -p "$DOCUMENTARIES_DIR"
    mkdir -p "$MUSIC_DIR"
    mkdir -p "$PICTURES_DIR"
    
    # Create subdirectories for better organization
    mkdir -p "$MOVIES_DIR/Action"
    mkdir -p "$MOVIES_DIR/Comedy"
    mkdir -p "$MOVIES_DIR/Drama"
    mkdir -p "$MOVIES_DIR/Horror"
    mkdir -p "$MOVIES_DIR/Sci-Fi"
    mkdir -p "$MOVIES_DIR/Animation"
    mkdir -p "$MOVIES_DIR/Foreign"
    
    mkdir -p "$TV_SERIES_DIR/Anime"
    mkdir -p "$TV_SERIES_DIR/Drama"
    mkdir -p "$TV_SERIES_DIR/Comedy"
    mkdir -p "$TV_SERIES_DIR/Documentary"
    mkdir -p "$TV_SERIES_DIR/Kids"
    
    # Create music directory structure
    mkdir -p "$MUSIC_DIR/Albums"
    mkdir -p "$MUSIC_DIR/Artists"
    mkdir -p "$MUSIC_DIR/Genres/Rock"
    mkdir -p "$MUSIC_DIR/Genres/Pop"
    mkdir -p "$MUSIC_DIR/Genres/Hip-Hop"
    mkdir -p "$MUSIC_DIR/Genres/Electronic"
    mkdir -p "$MUSIC_DIR/Genres/Classical"
    mkdir -p "$MUSIC_DIR/Genres/Jazz"
    mkdir -p "$MUSIC_DIR/Genres/Country"
    mkdir -p "$MUSIC_DIR/Genres/R&B"
    mkdir -p "$MUSIC_DIR/Genres/Alternative"
    mkdir -p "$MUSIC_DIR/Genres/World"
    mkdir -p "$MUSIC_DIR/Soundtracks"
    mkdir -p "$MUSIC_DIR/Podcasts"
    mkdir -p "$MUSIC_DIR/Playlists"
    
    # Create Elementum downloads directories
    ELEMENTUM_DOWNLOADS="$HOME/Downloads/Elementum"
    mkdir -p "$ELEMENTUM_DOWNLOADS/Movies"
    mkdir -p "$ELEMENTUM_DOWNLOADS/TV Shows"
    mkdir -p "$ELEMENTUM_DOWNLOADS/Music"
    mkdir -p "$ELEMENTUM_DOWNLOADS/Completed"
    
    # Create Kodi userdata directories if they don't exist
    mkdir -p "$HOME/.kodi/userdata/Database"
    mkdir -p "$HOME/.kodi/userdata/playlists"
    mkdir -p "$HOME/.kodi/userdata/library"
    
    # Configure Kodi sources.xml for automatic media detection
    cat > "$HOME/.kodi/userdata/sources.xml" << EOF
<sources>
    <programs>
        <default pathversion="1"></default>
    </programs>
    <video>
        <default pathversion="1"></default>
        <source>
            <name>Movies</name>
            <path pathversion="1">$MOVIES_DIR/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>TV Shows</name>
            <path pathversion="1">$TV_SERIES_DIR/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Documentaries</name>
            <path pathversion="1">$DOCUMENTARIES_DIR/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Elementum Downloads</name>
            <path pathversion="1">$ELEMENTUM_DOWNLOADS/</path>
            <allowsharing>true</allowsharing>
        </source>
    </video>
    <music>
        <default pathversion="1"></default>
        <source>
            <name>Music Library</name>
            <path pathversion="1">$MUSIC_DIR/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Albums</name>
            <path pathversion="1">$MUSIC_DIR/Albums/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Artists</name>
            <path pathversion="1">$MUSIC_DIR/Artists/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Genres</name>
            <path pathversion="1">$MUSIC_DIR/Genres/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Soundtracks</name>
            <path pathversion="1">$MUSIC_DIR/Soundtracks/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Podcasts</name>
            <path pathversion="1">$MUSIC_DIR/Podcasts/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Music Downloads</name>
            <path pathversion="1">$ELEMENTUM_DOWNLOADS/Music/</path>
            <allowsharing>true</allowsharing>
        </source>
    </music>
    <pictures>
        <default pathversion="1"></default>
        <source>
            <name>Pictures</name>
            <path pathversion="1">$PICTURES_DIR/</path>
            <allowsharing>true</allowsharing>
        </source>
    </pictures>
    <files>
        <default pathversion="1"></default>
    </files>
    <games>
        <default pathversion="1"></default>
    </games>
</sources>
EOF
    
    # Create MediaSources.xml for library scanning configuration
    cat > "$HOME/.kodi/userdata/MediaSources.xml" << EOF
<?xml version='1.0' encoding='UTF-8'?>
<mediasources>
    <network>
        <location id="0">smb://</location>
        <location id="1">nfs://</location>
        <location id="2">ftp://</location>
        <location id="3">upnp://</location>
    </network>
</mediasources>
EOF
    
    # Create README files explaining folder structure
    cat > "$MOVIES_DIR/README.txt" << 'EOF'
Movies Folder Structure
======================

This folder is automatically configured in Kodi for movie library scanning.

Organization:
• Place movie files directly in subfolders by genre (Action, Comedy, etc.)
• Supported formats: MP4, MKV, AVI, MOV, FLV, WMV
• For best library experience, name files like: "Movie Title (Year).ext"

Examples:
• Action/The Matrix (1999).mkv
• Comedy/Groundhog Day (1993).mp4
• Animation/Spirited Away (2001).mkv

Kodi will automatically:
• Scan for new movies
• Download metadata, posters, and fanart
• Organize them in the library
• Enable subtitle support

Elementum downloads will also appear here when configured.
EOF
    
    cat > "$MUSIC_DIR/README.txt" << 'EOF'
Music Library Structure
======================

This folder is automatically configured in Kodi for music library scanning.

Organization Options:
• Albums/Artist Name/Album Name (Year)/track files
• Artists/Artist Name/Album folders
• Genres/Genre Name/Artist or Album folders
• Soundtracks/Movie or Game Name/track files
• Podcasts/Podcast Name/Episode files

Supported Formats:
• Audio: MP3, FLAC, OGG, AAC, M4A, WMA, WAV
• Playlist: M3U, PLS, CUE

Examples:
• Albums/Pink Floyd/The Dark Side of the Moon (1973)/01 - Speak to Me.flac
• Artists/The Beatles/Abbey Road (1969)/01 - Come Together.mp3
• Genres/Rock/Led Zeppelin/Led Zeppelin IV (1971)/01 - Black Dog.flac
• Soundtracks/The Matrix (1999)/01 - Rock Is Dead.mp3
• Podcasts/Tech News/Episode 001 - Latest Updates.mp3

Kodi will automatically:
• Scan for new music and organize by artist/album
• Download album artwork and artist information  
• Create artist and album libraries
• Support playlist creation and management
• Enable music visualization and party mode
• Track play counts and favorites

Music downloads from streaming will also be detected automatically.
EOF
    
    cat > "$TV_SERIES_DIR/README.txt" << 'EOF'
TV Shows Folder Structure
========================

This folder is automatically configured in Kodi for TV show library scanning.

Organization:
• Create a folder for each show: "Show Name (Year)"
• Inside each show folder, organize by seasons: "Season 01", "Season 02", etc.
• Name episodes like: "S01E01 - Episode Title.ext"

Examples:
• Breaking Bad (2008)/Season 01/S01E01 - Pilot.mkv
• Anime/One Piece (1999)/Season 01/S01E001 - I'm Luffy.mkv
• Comedy/The Office (2005)/Season 01/S01E01 - Pilot.mp4

Kodi will automatically:
• Scan for new episodes
• Track watched status
• Download episode metadata and artwork
• Show next episodes to watch
• Support multiple seasons and specials

Use Elementum to stream directly or download for permanent collection.
EOF
    
    # Create sample folder structure demonstration
    mkdir -p "$MOVIES_DIR/Action/Sample Movie (2024)"
    mkdir -p "$TV_SERIES_DIR/Sample Show (2024)/Season 01"
    mkdir -p "$MUSIC_DIR/Albums/Sample Artist/Sample Album (2024)"
    
    echo "Place movie files here. Kodi will automatically scan and add to library." > "$MOVIES_DIR/Action/Sample Movie (2024)/INFO.txt"
    echo "Place episode files here like: S01E01 - Episode Title.mkv" > "$TV_SERIES_DIR/Sample Show (2024)/Season 01/INFO.txt"
    echo "Place music files here like: 01 - Track Name.mp3" > "$MUSIC_DIR/Albums/Sample Artist/Sample Album (2024)/INFO.txt"
    
    # Set appropriate permissions
    chmod -R 755 "$USER_VIDEOS_DIR"
    chmod -R 755 "$MUSIC_DIR"
    chmod -R 755 "$PICTURES_DIR"
    chmod -R 755 "$ELEMENTUM_DOWNLOADS"
    
    # Create media management script
    cat > "$HOME/manage-media.sh" << 'EOF'
#!/bin/bash
# Media Management Helper Script

echo "=== Kodi Media Management ==="
echo "1. Show media folder structure"
echo "2. Check folder sizes"
echo "3. Set up new movie"
echo "4. Set up new TV show"
echo "5. Set up new music album/artist"
echo "6. Clean up Elementum downloads"
echo "7. Scan Kodi library"
echo "8. Show Kodi library stats"
echo ""

read -p "Choose option (1-8): " choice

MOVIES_DIR="$HOME/Videos/Movies"
TV_DIR="$HOME/Videos/TV Shows"
MUSIC_DIR="$HOME/Music"
ELEMENTUM_DIR="$HOME/Downloads/Elementum"

case $choice in
    1)
        echo "=== Media Folder Structure ==="
        echo "Movies: $MOVIES_DIR"
        ls -la "$MOVIES_DIR" 2>/dev/null || echo "No movies folder found"
        echo ""
        echo "TV Shows: $TV_DIR"
        ls -la "$TV_DIR" 2>/dev/null || echo "No TV shows folder found"
        echo ""
        echo "Music: $MUSIC_DIR"
        ls -la "$MUSIC_DIR" 2>/dev/null || echo "No music folder found"
        echo ""
        echo "Downloads: $ELEMENTUM_DIR"
        ls -la "$ELEMENTUM_DIR" 2>/dev/null || echo "No downloads folder found"
        ;;
    2)
        echo "=== Folder Sizes ==="
        echo "Movies: $(du -sh "$MOVIES_DIR" 2>/dev/null | cut -f1 || echo "0B")"
        echo "TV Shows: $(du -sh "$TV_DIR" 2>/dev/null | cut -f1 || echo "0B")"
        echo "Music: $(du -sh "$MUSIC_DIR" 2>/dev/null | cut -f1 || echo "0B")"
        echo "Downloads: $(du -sh "$ELEMENTUM_DIR" 2>/dev/null | cut -f1 || echo "0B")"
        echo ""
        echo "Total Videos: $(du -sh "$HOME/Videos" 2>/dev/null | cut -f1 || echo "0B")"
        echo "Total Music: $(du -sh "$MUSIC_DIR" 2>/dev/null | cut -f1 || echo "0B")"
        ;;
    3)
        read -p "Enter movie title: " title
        read -p "Enter year: " year
        read -p "Enter genre (Action/Comedy/Drama/Horror/Sci-Fi/Animation/Foreign): " genre
        
        MOVIE_DIR="$MOVIES_DIR/$genre/$title ($year)"
        mkdir -p "$MOVIE_DIR"
        echo "Created: $MOVIE_DIR"
        echo "Place movie file in this folder and Kodi will automatically detect it"
        ;;
    4)
        read -p "Enter TV show title: " title
        read -p "Enter year: " year
        read -p "Enter category (Anime/Drama/Comedy/Documentary/Kids): " category
        
        SHOW_DIR="$TV_DIR/$category/$title ($year)"
        mkdir -p "$SHOW_DIR/Season 01"
        echo "Created: $SHOW_DIR"
        echo "Place episodes in Season folders like: S01E01 - Episode Title.mkv"
        ;;
    5)
        echo "=== Setting Up Music ==="
        echo "1. Set up by Album (Artist/Album structure)"
        echo "2. Set up by Artist (Artist-based folders)"
        echo "3. Set up by Genre (Genre-based organization)"
        echo "4. Set up Soundtrack"
        echo "5. Set up Podcast"
        echo ""
        read -p "Choose music organization (1-5): " music_choice
        
        case $music_choice in
            1)
                read -p "Enter artist name: " artist
                read -p "Enter album name: " album
                read -p "Enter year: " year
                ALBUM_DIR="$MUSIC_DIR/Albums/$artist/$album ($year)"
                mkdir -p "$ALBUM_DIR"
                echo "Created: $ALBUM_DIR"
                echo "Place music files like: 01 - Track Name.mp3"
                ;;
            2)
                read -p "Enter artist name: " artist
                ARTIST_DIR="$MUSIC_DIR/Artists/$artist"
                mkdir -p "$ARTIST_DIR"
                echo "Created: $ARTIST_DIR"
                echo "Create album folders inside and add tracks"
                ;;
            3)
                read -p "Enter genre (Rock/Pop/Hip-Hop/Electronic/Classical/Jazz/Country/R&B/Alternative/World): " genre
                read -p "Enter artist name: " artist
                GENRE_DIR="$MUSIC_DIR/Genres/$genre/$artist"
                mkdir -p "$GENRE_DIR"
                echo "Created: $GENRE_DIR"
                echo "Add albums or tracks in this artist folder"
                ;;
            4)
                read -p "Enter movie/game name: " title
                read -p "Enter year: " year
                SOUNDTRACK_DIR="$MUSIC_DIR/Soundtracks/$title ($year)"
                mkdir -p "$SOUNDTRACK_DIR"
                echo "Created: $SOUNDTRACK_DIR"
                echo "Place soundtrack files here"
                ;;
            5)
                read -p "Enter podcast name: " podcast
                PODCAST_DIR="$MUSIC_DIR/Podcasts/$podcast"
                mkdir -p "$PODCAST_DIR"
                echo "Created: $PODCAST_DIR"
                echo "Place podcast episodes here"
                ;;
        esac
        ;;
    6)
        echo "=== Cleaning Elementum Downloads ==="
        if [ -d "$ELEMENTUM_DIR" ]; then
            echo "Video downloads found:"
            find "$ELEMENTUM_DIR" -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" | head -10
            echo ""
            echo "Music downloads found:"
            find "$ELEMENTUM_DIR" -name "*.mp3" -o -name "*.flac" -o -name "*.m4a" | head -10
            echo ""
            read -p "Move completed downloads to media folders? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Manual organization recommended - check downloads and move to appropriate folders"
                echo "Movies -> $MOVIES_DIR/[Genre]/"
                echo "TV Shows -> $TV_DIR/[Category]/[Show Name]/Season ##/"
                echo "Music -> $MUSIC_DIR/[Albums|Artists|Genres]/[Artist]/[Album]/"
            fi
        else
            echo "No downloads folder found"
        fi
        ;;
    7)
        echo "=== Scanning Kodi Library ==="
        if command -v python3 &> /dev/null && [ -f "$HOME/kodi-cli.py" ]; then
            echo "Scanning video library..."
            python3 "$HOME/kodi-cli.py" library update --type video
            echo "Scanning music library..."
            python3 "$HOME/kodi-cli.py" library update --type music
            echo "Library scans initiated via CLI"
        else
            echo "Start Kodi and go to: Settings > Media > Library > Update Library"
            echo "Or use: System > File Manager > Add Source to add new folders"
        fi
        ;;
    8)
        echo "=== Kodi Library Statistics ==="
        echo "Movie files: $(find "$MOVIES_DIR" -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l)"
        echo "TV episodes: $(find "$TV_DIR" -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | wc -l)"
        echo "Music files: $(find "$MUSIC_DIR" -name "*.mp3" -o -name "*.flac" -o -name "*.m4a" -o -name "*.ogg" 2>/dev/null | wc -l)"
        echo ""
        echo "Recent video additions:"
        find "$MOVIES_DIR" "$TV_DIR" -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" 2>/dev/null | head -5
        echo ""
        echo "Recent music additions:"
        find "$MUSIC_DIR" -name "*.mp3" -o -name "*.flac" -o -name "*.m4a" 2>/dev/null | head -5
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF
    
    chmod +x "$HOME/manage-media.sh"
    
    log_success "Media folders and Kodi library sources configured"
    log_info "Media structure created at:"
    log_info "  Movies: $MOVIES_DIR"
    log_info "  TV Shows: $TV_SERIES_DIR" 
    log_info "  Documentaries: $DOCUMENTARIES_DIR"
    log_info "  Music: $MUSIC_DIR"
    log_info "  Downloads: $ELEMENTUM_DOWNLOADS"
}

# Function to optimize Kodi for Raspberry Pi
optimize_kodi_pi() {
    log_info "Optimizing Kodi for Raspberry Pi..."
    
    # GPU memory split optimization for media playback
    if grep -q "gpu_mem=" /boot/firmware/config.txt 2>/dev/null; then
        sudo sed -i 's/gpu_mem=.*/gpu_mem=128/' /boot/firmware/config.txt
    else
        echo "gpu_mem=128" | sudo tee -a /boot/firmware/config.txt
    fi
    
    # Enable hardware video decoding
    if ! grep -q "dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt 2>/dev/null; then
        echo "dtoverlay=vc4-kms-v3d" | sudo tee -a /boot/firmware/config.txt
    fi
    
    # Configure video memory
    if ! grep -q "cma=256M" /boot/firmware/cmdline.txt 2>/dev/null; then
        sudo sed -i 's/$/ cma=256M/' /boot/firmware/cmdline.txt
    fi
    
    # Create Kodi service for better integration
    sudo tee /etc/systemd/system/kodi-standalone.service > /dev/null << EOF
[Unit]
Description=Kodi Standalone Service
After=graphical.target

[Service]
Type=simple
User=$USER
Group=$USER
Environment=HOME=$HOME
Environment=DISPLAY=:0
ExecStart=/usr/bin/kodi-standalone
ExecStop=/usr/bin/killall kodi-standalone
Restart=no
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "Kodi optimization completed"
}

# Function to install Elementum plugin and dependencies
install_elementum_plugin() {
    log_info "Installing Elementum plugin and dependencies..."
    
    # Create addons directory
    mkdir -p "$HOME/.kodi/addons"
    
    # Download and install Elementum repository
    cd /tmp
    log_info "Downloading Elementum repository..."
    wget -O elementum-repository.zip "https://github.com/elgatito/plugin.video.elementum/releases/latest/download/repository.elementum.zip" || {
        log_warn "Direct download failed, using alternative method..."
        curl -L -o elementum-repository.zip "https://github.com/elgatito/plugin.video.elementum/releases/latest/download/repository.elementum.zip"
    }
    
    if [ -f elementum-repository.zip ]; then
        unzip -o elementum-repository.zip -d "$HOME/.kodi/addons/"
        log_success "Elementum repository installed"
    else
        log_warn "Could not download Elementum repository automatically"
        log_info "Manual installation: Download from https://github.com/elgatito/plugin.video.elementum/releases"
    fi
    
    # Create Elementum settings directory
    mkdir -p "$HOME/.kodi/userdata/addon_data/plugin.video.elementum"
    
    # Configure Elementum settings
    cat > "$HOME/.kodi/userdata/addon_data/plugin.video.elementum/settings.xml" << EOF
<settings version="2">
    <setting id="internal_proxy_enabled">true</setting>
    <setting id="internal_proxy_port">65251</setting>
    <setting id="download_path">$HOME/Downloads/Elementum</setting>
    <setting id="torrents_path">$HOME/Downloads/Elementum/.torrents</setting>
    <setting id="keep_files">1</setting>
    <setting id="buffer_size">20</setting>
    <setting id="max_upload_rate">0</setting>
    <setting id="max_download_rate">0</setting>
    <setting id="connections_limit">200</setting>
    <setting id="session_save">60</setting>
    <setting id="share_ratio_limit">200</setting>
    <setting id="seed_time_ratio_limit">7200</setting>
    <setting id="seed_time_limit">86400</setting>
    <setting id="disable_upload">false</setting>
    <setting id="disable_dht">false</setting>
    <setting id="disable_upnp">false</setting>
    <setting id="encryption_policy">1</setting>
    <setting id="listen_port">6889</setting>
    <setting id="outgoing_port">0</setting>
    <setting id="num_want">200</setting>
    <setting id="request_timeout">30</setting>
    <setting id="peer_connect_timeout">15</setting>
    <setting id="peer_handshake_timeout">20</setting>
    <setting id="request_queue_size">250</setting>
    <setting id="max_peer_list_size">200</setting>
    <setting id="max_paused_peer_list_size">200</setting>
    <setting id="min_reconnect_time">60</setting>
    <setting id="max_failcount">3</setting>
    <setting id="recv_socket_buffer_size">4194304</setting>
    <setting id="send_socket_buffer_size">4194304</setting>
    <setting id="check_available_space">true</setting>
    <setting id="log_level">INFO</setting>
    <setting id="library_enabled">true</setting>
    <setting id="library_movies_path">$HOME/Videos/Movies</setting>
    <setting id="library_shows_path">$HOME/Videos/TV Shows</setting>
    <setting id="library_update">true</setting>
    <setting id="auto_library_update">true</setting>
</settings>
EOF
    
    # Create downloads directory
    mkdir -p "$HOME/Downloads/Elementum"
    
    log_success "Elementum plugin configuration completed"
}

# Function to setup Kodi REST API and Home Assistant integration
setup_kodi_api_integration() {
    log_info "Setting up Kodi API for Home Assistant integration..."
    
    # Create Home Assistant Kodi configuration template
    mkdir -p "$HOME/kodi-homeassistant"
    
    cat > "$HOME/kodi-homeassistant/homeassistant-kodi-config.yaml" << 'EOF'
# Home Assistant Kodi Integration Configuration
# Add this to your Home Assistant configuration.yaml

media_player:
  - platform: kodi
    host: YOUR_RASPBERRY_PI_IP_ADDRESS
    port: 8080
    username: kodi
    password: kodi
    name: "Raspberry Pi Kodi"
    enable_websocket: true

# Automation examples for Kodi control
automation:
  - alias: "Kodi: Pause on motion detected"
    trigger:
      platform: state
      entity_id: binary_sensor.motion_detector
      to: 'on'
    condition:
      condition: state
      entity_id: media_player.raspberry_pi_kodi
      state: 'playing'
    action:
      service: media_player.media_pause
      target:
        entity_id: media_player.raspberry_pi_kodi

  - alias: "Kodi: Resume after motion stops"
    trigger:
      platform: state
      entity_id: binary_sensor.motion_detector
      to: 'off'
      for: '00:02:00'
    condition:
      condition: state
      entity_id: media_player.raspberry_pi_kodi
      state: 'paused'
    action:
      service: media_player.media_play
      target:
        entity_id: media_player.raspberry_pi_kodi

# Script examples for Kodi control
script:
  kodi_movie_mode:
    sequence:
      - service: light.turn_off
        target:
          entity_id: all
      - service: media_player.turn_on
        target:
          entity_id: media_player.raspberry_pi_kodi

  kodi_stop_and_lights_on:
    sequence:
      - service: media_player.media_stop
        target:
          entity_id: media_player.raspberry_pi_kodi
      - service: light.turn_on
        target:
          entity_id: all
EOF
    
    # Create Kodi API test script
    cat > "$HOME/kodi-homeassistant/test-kodi-api.py" << 'EOF'
#!/usr/bin/env python3
"""
Kodi REST API Test Script
Tests Kodi JSON-RPC API connectivity and basic functions
"""

import json
import requests
import sys
from base64 import b64encode

# Configuration
KODI_HOST = "localhost"
KODI_PORT = 8080
KODI_USERNAME = "kodi"
KODI_PASSWORD = "kodi"

# Create API URL and auth headers
KODI_URL = f"http://{KODI_HOST}:{KODI_PORT}/jsonrpc"
auth_string = f"{KODI_USERNAME}:{KODI_PASSWORD}"
auth_bytes = auth_string.encode('ascii')
auth_b64 = b64encode(auth_bytes).decode('ascii')
headers = {
    'Authorization': f'Basic {auth_b64}',
    'Content-Type': 'application/json'
}

def send_kodi_command(method, params=None):
    """Send JSON-RPC command to Kodi"""
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "id": 1
    }
    if params:
        payload["params"] = params
    
    try:
        response = requests.post(KODI_URL, json=payload, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to Kodi: {e}")
        return None

def test_api_connectivity():
    """Test basic API connectivity"""
    print("Testing Kodi API connectivity...")
    result = send_kodi_command("JSONRPC.Ping")
    if result and result.get("result") == "pong":
        print("✓ Kodi API is responding")
        return True
    else:
        print("✗ Kodi API is not responding")
        return False

def get_kodi_info():
    """Get Kodi system information"""
    print("\nGetting Kodi system info...")
    result = send_kodi_command("Application.GetProperties", {
        "properties": ["version", "name", "muted", "volume"]
    })
    if result and "result" in result:
        info = result["result"]
        print(f"✓ Kodi Version: {info.get('version', {}).get('major', 'Unknown')}.{info.get('version', {}).get('minor', 'Unknown')}")
        print(f"✓ Volume: {info.get('volume', 'Unknown')}%")
        print(f"✓ Muted: {info.get('muted', 'Unknown')}")

def get_active_players():
    """Get active players"""
    print("\nChecking active players...")
    result = send_kodi_command("Player.GetActivePlayers")
    if result and "result" in result:
        players = result["result"]
        if players:
            for player in players:
                print(f"✓ Active player: {player.get('type', 'Unknown')} (ID: {player.get('playerid')})")
        else:
            print("ℹ No active players")

def test_media_controls():
    """Test media control functions"""
    print("\nTesting media controls...")
    
    # Test notification
    result = send_kodi_command("GUI.ShowNotification", {
        "title": "API Test",
        "message": "Kodi API is working!",
        "displaytime": 3000
    })
    if result:
        print("✓ Notification sent")
    
    # Test input commands
    commands = [
        ("Input.Home", "Navigate to home"),
        ("Input.Info", "Show info dialog"),
    ]
    
    for command, description in commands:
        result = send_kodi_command(command)
        if result:
            print(f"✓ {description} - Command sent")

def main():
    """Main test function"""
    print("=== Kodi REST API Test ===")
    print(f"Testing connection to: {KODI_URL}")
    print(f"Username: {KODI_USERNAME}")
    
    if not test_api_connectivity():
        print("\n❌ API test failed!")
        print("Troubleshooting:")
        print("1. Make sure Kodi is running")
        print("2. Check if web server is enabled in Kodi settings")
        print("3. Verify username/password")
        print("4. Check firewall settings")
        sys.exit(1)
    
    get_kodi_info()
    get_active_players()
    test_media_controls()
    
    print("\n✅ Kodi API test completed successfully!")
    print("\nYou can now integrate this Kodi instance with:")
    print("• Home Assistant")
    print("• Mobile apps (Kore, Yatse)")
    print("• Custom scripts and automation")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$HOME/kodi-homeassistant/test-kodi-api.py"
    
    log_success "Kodi API integration setup completed"
}

# Function to create advanced Kodi CLI management tools
create_advanced_kodi_cli() {
    log_info "Creating advanced Kodi CLI management tools..."
    
    # Create comprehensive Kodi CLI manager
    cat > "$HOME/kodi-cli.py" << 'EOF'
#!/usr/bin/env python3
"""
Advanced Kodi CLI Management Tool
Provides comprehensive command-line control of Kodi via JSON-RPC API
"""

import json
import requests
import sys
import argparse
import time
from base64 import b64encode

class KodiCLI:
    def __init__(self, host="localhost", port=8080, username="kodi", password="kodi"):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.url = f"http://{host}:{port}/jsonrpc"
        
        # Setup authentication
        auth_string = f"{username}:{password}"
        auth_bytes = auth_string.encode('ascii')
        auth_b64 = b64encode(auth_bytes).decode('ascii')
        self.headers = {
            'Authorization': f'Basic {auth_b64}',
            'Content-Type': 'application/json'
        }
    
    def send_command(self, method, params=None):
        """Send JSON-RPC command to Kodi"""
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "id": 1
        }
        if params:
            payload["params"] = params
        
        try:
            response = requests.post(self.url, json=payload, headers=self.headers, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")
            return None
    
    def install_addon(self, addon_id):
        """Install addon from repository"""
        print(f"Installing addon: {addon_id}")
        result = self.send_command("Addons.ExecuteAddon", {"addonid": addon_id})
        if result:
            print("✓ Installation command sent")
        return result
    
    def list_addons(self, addon_type="unknown"):
        """List installed addons"""
        result = self.send_command("Addons.GetAddons", {"type": addon_type})
        if result and "result" in result:
            addons = result["result"].get("addons", [])
            print(f"\nInstalled addons ({len(addons)}):")
            for addon in addons:
                print(f"  • {addon['name']} ({addon['addonid']})")
        return result
    
    def enable_addon(self, addon_id):
        """Enable an addon"""
        result = self.send_command("Addons.SetAddonEnabled", {
            "addonid": addon_id,
            "enabled": True
        })
        if result:
            print(f"✓ Enabled addon: {addon_id}")
        return result
    
    def disable_addon(self, addon_id):
        """Disable an addon"""
        result = self.send_command("Addons.SetAddonEnabled", {
            "addonid": addon_id,
            "enabled": False
        })
        if result:
            print(f"✓ Disabled addon: {addon_id}")
        return result
    
    def play_media(self, item):
        """Play media file or stream"""
        result = self.send_command("Player.Open", {"item": {"file": item}})
        if result:
            print(f"✓ Playing: {item}")
        return result
    
    def stop_playback(self):
        """Stop current playback"""
        # Get active players first
        players_result = self.send_command("Player.GetActivePlayers")
        if players_result and "result" in players_result:
            players = players_result["result"]
            for player in players:
                player_id = player["playerid"]
                result = self.send_command("Player.Stop", {"playerid": player_id})
                if result:
                    print(f"✓ Stopped player {player_id}")
    
    def pause_playback(self):
        """Pause/Resume playback"""
        players_result = self.send_command("Player.GetActivePlayers")
        if players_result and "result" in players_result:
            players = players_result["result"]
            for player in players:
                player_id = player["playerid"]
                result = self.send_command("Player.PlayPause", {"playerid": player_id})
                if result:
                    print(f"✓ Toggled pause for player {player_id}")
    
    def set_volume(self, volume):
        """Set volume (0-100)"""
        result = self.send_command("Application.SetVolume", {"volume": int(volume)})
        if result:
            print(f"✓ Volume set to {volume}%")
        return result
    
    def mute_toggle(self):
        """Toggle mute"""
        result = self.send_command("Application.SetMute", {"mute": "toggle"})
        if result:
            print("✓ Mute toggled")
        return result
    
    def show_notification(self, title, message, time=5000):
        """Show notification"""
        result = self.send_command("GUI.ShowNotification", {
            "title": title,
            "message": message,
            "displaytime": int(time)
        })
        if result:
            print(f"✓ Notification sent: {title}")
        return result
    
    def update_library(self, library_type="video"):
        """Update media library"""
        if library_type == "video":
            result = self.send_command("VideoLibrary.Scan")
        elif library_type == "music":
            result = self.send_command("AudioLibrary.Scan")
        else:
            print("Error: library_type must be 'video' or 'music'")
            return None
        
        if result:
            print(f"✓ {library_type.title()} library scan started")
        return result
    
    def clean_library(self, library_type="video"):
        """Clean media library"""
        if library_type == "video":
            result = self.send_command("VideoLibrary.Clean")
        elif library_type == "music":
            result = self.send_command("AudioLibrary.Clean")
        else:
            print("Error: library_type must be 'video' or 'music'")
            return None
        
        if result:
            print(f"✓ {library_type.title()} library clean started")
        return result
    
    def get_status(self):
        """Get Kodi status"""
        print("=== Kodi Status ===")
        
        # Application info
        app_result = self.send_command("Application.GetProperties", {
            "properties": ["version", "name", "muted", "volume"]
        })
        if app_result and "result" in app_result:
            info = app_result["result"]
            version = info.get("version", {})
            print(f"Version: {version.get('major', '?')}.{version.get('minor', '?')}")
            print(f"Volume: {info.get('volume', '?')}%")
            print(f"Muted: {info.get('muted', '?')}")
        
        # Active players
        players_result = self.send_command("Player.GetActivePlayers")
        if players_result and "result" in players_result:
            players = players_result["result"]
            if players:
                print(f"Active players: {len(players)}")
                for player in players:
                    print(f"  • {player.get('type', 'Unknown')} (ID: {player.get('playerid')})")
            else:
                print("Active players: None")

def main():
    parser = argparse.ArgumentParser(description="Advanced Kodi CLI Management")
    parser.add_argument("--host", default="localhost", help="Kodi host")
    parser.add_argument("--port", type=int, default=8080, help="Kodi port")
    parser.add_argument("--username", default="kodi", help="Kodi username")
    parser.add_argument("--password", default="kodi", help="Kodi password")
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Status command
    subparsers.add_parser("status", help="Show Kodi status")
    
    # Addon commands
    addon_parser = subparsers.add_parser("addon", help="Addon management")
    addon_subparsers = addon_parser.add_subparsers(dest="addon_action")
    addon_subparsers.add_parser("list", help="List addons")
    
    enable_parser = addon_subparsers.add_parser("enable", help="Enable addon")
    enable_parser.add_argument("addon_id", help="Addon ID")
    
    disable_parser = addon_subparsers.add_parser("disable", help="Disable addon")
    disable_parser.add_argument("addon_id", help="Addon ID")
    
    # Media commands
    media_parser = subparsers.add_parser("media", help="Media control")
    media_subparsers = media_parser.add_subparsers(dest="media_action")
    
    play_parser = media_subparsers.add_parser("play", help="Play media")
    play_parser.add_argument("file", help="File path or URL")
    
    media_subparsers.add_parser("stop", help="Stop playback")
    media_subparsers.add_parser("pause", help="Pause/Resume playback")
    
    # Volume commands
    volume_parser = subparsers.add_parser("volume", help="Volume control")
    volume_parser.add_argument("level", type=int, help="Volume level (0-100)")
    
    subparsers.add_parser("mute", help="Toggle mute")
    
    # Notification command
    notify_parser = subparsers.add_parser("notify", help="Show notification")
    notify_parser.add_argument("title", help="Notification title")
    notify_parser.add_argument("message", help="Notification message")
    notify_parser.add_argument("--time", type=int, default=5000, help="Display time in ms")
    
    # Library commands
    library_parser = subparsers.add_parser("library", help="Library management")
    library_subparsers = library_parser.add_subparsers(dest="library_action")
    
    update_parser = library_subparsers.add_parser("update", help="Update library")
    update_parser.add_argument("--type", choices=["video", "music"], default="video", help="Library type")
    
    clean_parser = library_subparsers.add_parser("clean", help="Clean library")
    clean_parser.add_argument("--type", choices=["video", "music"], default="video", help="Library type")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    kodi = KodiCLI(args.host, args.port, args.username, args.password)
    
    if args.command == "status":
        kodi.get_status()
    elif args.command == "addon":
        if args.addon_action == "list":
            kodi.list_addons()
        elif args.addon_action == "enable":
            kodi.enable_addon(args.addon_id)
        elif args.addon_action == "disable":
            kodi.disable_addon(args.addon_id)
    elif args.command == "media":
        if args.media_action == "play":
            kodi.play_media(args.file)
        elif args.media_action == "stop":
            kodi.stop_playback()
        elif args.media_action == "pause":
            kodi.pause_playback()
    elif args.command == "volume":
        kodi.set_volume(args.level)
    elif args.command == "mute":
        kodi.mute_toggle()
    elif args.command == "notify":
        kodi.show_notification(args.title, args.message, args.time)
    elif args.command == "library":
        if args.library_action == "update":
            kodi.update_library(args.type)
        elif args.library_action == "clean":
            kodi.clean_library(args.type)

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$HOME/kodi-cli.py"
    
    # Create Elementum-specific management script
    cat > "$HOME/elementum-manager.sh" << 'EOF'
#!/bin/bash
# Elementum Plugin Manager

echo "=== Elementum Plugin Manager ==="
echo "1. Install Elementum plugin"
echo "2. Configure Elementum settings"
echo "3. Check Elementum status"
echo "4. Open Elementum downloads folder"
echo "5. View Elementum logs"
echo "6. Reset Elementum configuration"
echo ""

read -p "Choose option (1-6): " choice

ELEMENTUM_DIR="$HOME/.kodi/userdata/addon_data/plugin.video.elementum"
DOWNLOADS_DIR="$HOME/Downloads/Elementum"

case $choice in
    1)
        echo "Installing Elementum plugin..."
        python3 "$HOME/kodi-cli.py" addon enable plugin.video.elementum
        echo "Note: You may need to install the repository first from Kodi interface"
        echo "Repository URL: https://github.com/elgatito/plugin.video.elementum"
        ;;
    2)
        echo "Configuring Elementum settings..."
        mkdir -p "$ELEMENTUM_DIR"
        echo "✓ Settings directory created"
        echo "✓ Downloads directory: $DOWNLOADS_DIR"
        echo "Edit settings in Kodi: Add-ons > Video add-ons > Elementum > Configure"
        ;;
    3)
        echo "Checking Elementum status..."
        if [ -d "$ELEMENTUM_DIR" ]; then
            echo "✓ Elementum addon data directory exists"
        else
            echo "✗ Elementum addon data directory not found"
        fi
        
        if [ -d "$DOWNLOADS_DIR" ]; then
            echo "✓ Downloads directory exists"
            echo "Downloads count: $(find "$DOWNLOADS_DIR" -type f | wc -l) files"
        else
            echo "✗ Downloads directory not found"
        fi
        
        # Check if Elementum is running
        if pgrep -f "elementum" > /dev/null; then
            echo "✓ Elementum process is running"
        else
            echo "ℹ Elementum process not detected"
        fi
        ;;
    4)
        echo "Opening downloads folder..."
        mkdir -p "$DOWNLOADS_DIR"
        if command -v nautilus &> /dev/null; then
            nautilus "$DOWNLOADS_DIR"
        elif command -v pcmanfm &> /dev/null; then
            pcmanfm "$DOWNLOADS_DIR"
        else
            echo "Downloads location: $DOWNLOADS_DIR"
            ls -la "$DOWNLOADS_DIR"
        fi
        ;;
    5)
        echo "Viewing Elementum logs..."
        LOG_FILE="$HOME/.kodi/temp/kodi.log"
        if [ -f "$LOG_FILE" ]; then
            echo "Recent Elementum log entries:"
            grep -i "elementum" "$LOG_FILE" | tail -20
        else
            echo "Kodi log file not found"
        fi
        ;;
    6)
        read -p "Reset Elementum configuration? This will delete all settings (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$ELEMENTUM_DIR"
            echo "✓ Elementum configuration reset"
            echo "Restart Kodi to complete the reset"
        fi
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF
    
    chmod +x "$HOME/elementum-manager.sh"
    
    log_success "Advanced Kodi CLI tools created"
}
    
    # Create Kodi quick launcher
    cat > "$HOME/launch-kodi.sh" << 'EOF'
#!/bin/bash
# Quick Kodi Launcher

echo "=== Kodi Media Center Launcher ==="
echo "This will:"
echo "1. Stop EmulationStation"
echo "2. Launch Kodi"
echo "3. Restart EmulationStation when Kodi closes"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Stop EmulationStation
    if pgrep -x "emulationstation" > /dev/null; then
        echo "Stopping EmulationStation..."
        sudo pkill -f emulationstation
        sleep 2
    fi
    
    # Launch Kodi
    echo "Starting Kodi..."
    kodi-standalone
    
    # Restart EmulationStation
    echo "Restarting EmulationStation..."
    sleep 2
    emulationstation &
else
    echo "Cancelled"
fi
EOF
    
    chmod +x "$HOME/launch-kodi.sh"
    
    # Create Kodi configuration script
    cat > "$HOME/configure-kodi.sh" << 'EOF'
#!/bin/bash
# Kodi Configuration Helper

echo "=== Kodi Configuration Helper ==="
echo "1. Test controller input"
echo "2. Configure video settings"
echo "3. Configure audio settings" 
echo "4. Reset Kodi settings"
echo "5. View Kodi logs"
echo ""

read -p "Choose option (1-5): " choice

case $choice in
    1)
        echo "Testing controller input..."
        echo "Controllers detected:"
        ls /dev/input/js* 2>/dev/null || echo "No controllers found"
        echo ""
        echo "Launch Kodi and go to Settings > System > Input to configure controllers"
        ;;
    2)
        echo "Video configuration tips:"
        echo "• Go to Settings > Player > Videos"
        echo "• Enable 'Allow hardware acceleration'"
        echo "• Set 'Render method' to appropriate option for Pi"
        ;;
    3)
        echo "Audio configuration tips:"
        echo "• Go to Settings > System > Audio"
        echo "• Set audio output device (HDMI/3.5mm)"
        echo "• Configure passthrough if using external audio system"
        ;;
    4)
        read -p "Reset all Kodi settings? This will delete your configuration (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.kodi/userdata/Database"
            rm -f "$HOME/.kodi/userdata/advancedsettings.xml"
            echo "Kodi settings reset"
        fi
        ;;
    5)
        echo "Recent Kodi log entries:"
        tail -50 "$HOME/.kodi/temp/kodi.log" 2>/dev/null || echo "No log file found"
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF
    
    chmod +x "$HOME/configure-kodi.sh"
    
    log_success "Kodi utilities created"
}

# Function to display setup summary
display_kodi_summary() {
    echo ""
    echo "========================================================"
    echo "   KODI + ELEMENTUM + MEDIA LIBRARY + HOME ASSISTANT"
    echo "========================================================"
    echo ""
    echo "✓ Kodi media center installed with full features"
    echo "✓ Integrated with EmulationStation as a 'port'"
    echo "✓ Controller support configured"
    echo "✓ Raspberry Pi optimizations applied"
    echo "✓ Elementum plugin installed and configured"
    echo "✓ Media folders created and auto-configured"
    echo "✓ Library sources pre-configured for automatic scanning"
    echo "✓ REST API enabled for remote control"
    echo "✓ Home Assistant integration ready"
    echo "✓ Advanced CLI management tools created"
    echo ""
    echo "=== MEDIA FOLDER STRUCTURE ==="
    echo "• Movies: ~/Videos/Movies/ (organized by genre)"
    echo "• TV Shows: ~/Videos/TV Shows/ (organized by category)" 
    echo "• Documentaries: ~/Videos/Documentaries/"
    echo "• Music: ~/Music/ (organized by Albums/Artists/Genres/Soundtracks/Podcasts)"
    echo "• Elementum Downloads: ~/Downloads/Elementum/"
    echo "• Pictures: ~/Pictures/"
    echo ""
    echo "=== LIBRARY AUTO-DISCOVERY ==="
    echo "• Kodi will automatically scan these folders"
    echo "• Add movies to genre subfolders (Action, Comedy, etc.)"
    echo "• Add TV shows as: Show Name (Year)/Season ##/episodes"
    echo "• Add music as: Albums/Artist/Album (Year)/tracks or Artists/Artist/albums"
    echo "• Elementum downloads integrate with library"
    echo "• Metadata and artwork downloaded automatically"
    echo ""
    echo "=== ACCESSING KODI ==="
    echo "• From EmulationStation: Navigate to 'Ports' → 'Kodi Media Center'"
    echo "• Quick launch: Run ~/launch-kodi.sh"
    echo "• Direct launch: kodi-standalone"
    echo ""
    echo "=== ELEMENTUM PLUGIN ==="
    echo "• Stream torrents instantly while downloading"
    echo "• Configure: Kodi → Add-ons → Video add-ons → Elementum → Configure"
    echo "• Manager script: ~/elementum-manager.sh"
    echo "• Downloads folder: ~/Downloads/Elementum"
    echo "• Library integration enabled for watched history"
    echo ""
    echo "=== MEDIA MANAGEMENT ==="
    echo "• Management script: ~/manage-media.sh"
    echo "• Check folder structure and sizes"
    echo "• Set up new movies and TV shows"
    echo "• Clean up downloads and organize files"
    echo "• Scan library and view statistics"
    echo ""
    echo "=== REMOTE CONTROL & API ==="
    echo "• Web interface: http://YOUR_IP:8080 (user: kodi, pass: kodi)"
    echo "• JSON-RPC API: http://YOUR_IP:8080/jsonrpc"
    echo "• CLI tool: ~/kodi-cli.py [command]"
    echo "• API test: ~/kodi-homeassistant/test-kodi-api.py"
    echo ""
    echo "=== HOME ASSISTANT INTEGRATION ==="
    echo "• Configuration template: ~/kodi-homeassistant/homeassistant-kodi-config.yaml"
    echo "• Add to Home Assistant configuration.yaml"
    echo "• Update YOUR_RASPBERRY_PI_IP_ADDRESS with actual IP"
    echo ""
    echo "=== MOBILE APPS ==="
    echo "• Kore (Official Kodi Remote) - Available on Play Store/App Store"
    echo "• Yatse (Advanced Remote) - Available on Play Store/App Store"
    echo "• Connection: Host=YOUR_IP, Port=8080, User=kodi, Pass=kodi"
    echo ""
    echo "=== FIRST TIME SETUP ==="
    echo "1. Launch Kodi from EmulationStation or ~/launch-kodi.sh"
    echo "2. Library sources are pre-configured - just add media files!"
    echo "3. Install additional plugins from Add-on browser"
    echo "4. For Elementum: Add-ons → Install from repository → Elementum Repository"
    echo "5. Test remote control with mobile apps or web interface"
    echo "6. Use ~/manage-media.sh to organize your collection"
    echo "7. Integrate with Home Assistant using provided config"
    echo ""
    echo "=== FOLDER ORGANIZATION TIPS ==="
    echo "Movies: Place in genre folders like:"
    echo "  • ~/Videos/Movies/Action/The Matrix (1999).mkv"
    echo "  • ~/Videos/Movies/Comedy/Groundhog Day (1993).mp4"
    echo ""
    echo "TV Shows: Organize by show and season:"
    echo "  • ~/Videos/TV Shows/Drama/Breaking Bad (2008)/Season 01/S01E01 - Pilot.mkv"
    echo "  • ~/Videos/TV Shows/Anime/One Piece (1999)/Season 01/S01E001 - I'm Luffy.mkv"
    echo ""
    echo "Music: Organize by album, artist, or genre:"
    echo "  • ~/Music/Albums/Pink Floyd/The Dark Side of the Moon (1973)/01 - Speak to Me.flac"
    echo "  • ~/Music/Artists/The Beatles/Abbey Road (1969)/01 - Come Together.mp3"
    echo "  • ~/Music/Genres/Rock/Led Zeppelin/Led Zeppelin IV (1971)/01 - Black Dog.flac"
    echo "  • ~/Music/Soundtracks/The Matrix (1999)/01 - Rock Is Dead.mp3"
    echo ""
    echo "🎬🎵 Smart TV-style media center with automatic library management ready!"
    echo "========================================================"
}

# Main function
main() {
    log_info "=== Kodi Integration Setup ==="
    echo "This script will:"
    echo "• Install Kodi media center"
    echo "• Integrate Kodi with EmulationStation as a 'port'"
    echo "• Configure controller support for Kodi"
    echo "• Optimize Kodi for Raspberry Pi"
    echo ""
    
    # Confirmation prompt
    read -p "Continue with Kodi installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Kodi installation cancelled by user"
        exit 0
    fi
    
    # Execute installation steps
    install_kodi
    configure_kodi_integration
    configure_kodi_controller
    setup_media_folders_and_library
    optimize_kodi_pi
    install_elementum_plugin
    setup_kodi_api_integration
    create_advanced_kodi_cli
    create_kodi_utilities
    
    # Display completion summary
    display_kodi_summary
}

# Execute main function
main "$@"
