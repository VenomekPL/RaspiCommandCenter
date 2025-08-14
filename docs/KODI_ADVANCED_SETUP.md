# Kodi Advanced Setup Guide

## Elementum Plugin + Home Assistant Integration + CLI Control + Auto Media Library

This guide covers the advanced Kodi features installed by the enhanced setup script, including automatic media folder creation and library configuration.

## 📁 **Auto-Configured Media Library**

### Pre-Created Folder Structure
The setup automatically creates and configures:

```
~/Videos/
├── Movies/ (organized by genre)
│   ├── Action/    ├── Comedy/    ├── Drama/
│   ├── Horror/    ├── Sci-Fi/    ├── Animation/
│   └── Foreign/
├── TV Shows/ (organized by category)  
│   ├── Anime/     ├── Drama/     ├── Comedy/
│   ├── Documentary/ └── Kids/
└── Documentaries/

~/Downloads/Elementum/
├── Movies/        ├── TV Shows/   └── Completed/
```

### Kodi Library Sources (Pre-configured)
- **Movies**: `~/Videos/Movies/` → Auto-scanned as Movies content
- **TV Shows**: `~/Videos/TV Shows/` → Auto-scanned as TV Shows content  
- **Documentaries**: `~/Videos/Documentaries/` → Auto-scanned as Movies content
- **Downloads**: `~/Downloads/Elementum/` → Auto-scanned as Mixed content

### Media Organization Examples
```bash
# Movies (auto-detected by Kodi)
~/Videos/Movies/Action/The Matrix (1999).mkv
~/Videos/Movies/Comedy/Groundhog Day (1993).mp4

# TV Shows (auto-detected with episodes)
~/Videos/TV Shows/Drama/Breaking Bad (2008)/Season 01/S01E01 - Pilot.mkv
~/Videos/TV Shows/Anime/One Piece (1999)/Season 01/S01E001 - I'm Luffy.mkv
```

### Management Tools
```bash
# Media management helper
~/manage-media.sh

# Features:
# • View folder structure and sizes
# • Set up new movie/TV show folders  
# • Clean up Elementum downloads
# • Scan Kodi library
# • Show library statistics
```

## 🎬 Elementum Plugin (Torrent Streaming)

### What is Elementum?
Elementum is a BitTorrent plugin for Kodi that allows streaming torrents directly without waiting for complete downloads.

### Installation
1. **Automatic Installation** (via script):
   ```bash
   cd ~/RaspiCommandCenter
   ./scripts/setup_kodi.sh
   ```

2. **Manual Installation**:
   - Download repository from: https://github.com/elgatito/plugin.video.elementum/releases
   - Install via Kodi: Add-ons → Install from zip file

### Configuration
1. **Launch Elementum Manager**:
   ```bash
   ~/elementum-manager.sh
   ```

2. **Key Settings in Kodi**:
   - Go to: Add-ons → Video add-ons → Elementum → Configure
   - **Download Path**: `~/Downloads/Elementum` (already configured)
   - **Buffer Size**: 20MB (recommended for Pi 5)
   - **Keep Files**: Yes (for rewatching)
   - **Upload Limit**: 0 (unlimited) or set based on your internet

### Using Elementum
1. Launch Kodi from EmulationStation
2. Go to Add-ons → Video add-ons → Elementum
3. Browse movies/TV shows or search
4. Select content and it will start streaming while downloading

## 🏠 Home Assistant Integration

### Setup in Home Assistant
1. **Copy configuration**:
   ```bash
   cat ~/kodi-homeassistant/homeassistant-kodi-config.yaml
   ```

2. **Add to Home Assistant** `configuration.yaml`:
   ```yaml
   media_player:
     - platform: kodi
       host: YOUR_RASPBERRY_PI_IP_ADDRESS  # Replace with actual IP
       port: 8080
       username: kodi
       password: kodi
       name: "Raspberry Pi Kodi"
       enable_websocket: true
   ```

3. **Restart Home Assistant** and the Kodi media player will appear

### Home Assistant Features
- **Media Control**: Play, pause, stop, volume control
- **Library Management**: Update/clean libraries
- **Notifications**: Send messages to Kodi
- **Automation**: Pause when motion detected, resume after timer
- **Status Monitoring**: Check what's playing, volume level

### Example Automations
```yaml
# Pause Kodi when doorbell rings
automation:
  - alias: "Pause Kodi on Doorbell"
    trigger:
      platform: state
      entity_id: binary_sensor.doorbell
      to: 'on'
    action:
      service: media_player.media_pause
      target:
        entity_id: media_player.raspberry_pi_kodi

# Movie mode script
script:
  movie_mode:
    sequence:
      - service: light.turn_off
        target:
          area_id: living_room
      - service: media_player.turn_on
        target:
          entity_id: media_player.raspberry_pi_kodi
```

## 📱 Mobile App Control

### Kore (Official Kodi Remote)
1. **Download**: Available on Google Play Store and Apple App Store
2. **Setup**:
   - Host: Your Raspberry Pi IP address
   - Port: 8080
   - Username: kodi
   - Password: kodi
3. **Features**: Full remote control, library browsing, queue management

### Yatse (Advanced Remote)
1. **Download**: Available on app stores (free + pro version)
2. **Setup**: Same connection details as Kore
3. **Extra Features**: Voice control, widgets, advanced automation

## 🖥️ CLI Control

### Basic CLI Usage
```bash
# Check Kodi status
python3 ~/kodi-cli.py status

# Media control
python3 ~/kodi-cli.py media play /path/to/movie.mkv
python3 ~/kodi-cli.py media pause
python3 ~/kodi-cli.py media stop

# Volume control
python3 ~/kodi-cli.py volume 75
python3 ~/kodi-cli.py mute

# Notifications
python3 ~/kodi-cli.py notify "Movie Night" "Starting movie in 5 minutes"

# Library management
python3 ~/kodi-cli.py library update
python3 ~/kodi-cli.py library clean

# Addon management
python3 ~/kodi-cli.py addon list
python3 ~/kodi-cli.py addon enable plugin.video.elementum
```

### Advanced CLI Examples
```bash
# Remote control from another device
python3 ~/kodi-cli.py --host 192.168.1.100 status

# Automation scripts
python3 ~/kodi-cli.py media play "https://archive.org/download/BigBuckBunny_124/Content/big_buck_bunny_720p_surround.mp4"

# Batch operations
for movie in ~/Movies/*.mkv; do
    python3 ~/kodi-cli.py notify "Adding" "$(basename "$movie")"
done
```

## 🔧 Configuration Files

### Key Locations
- **Kodi User Data**: `~/.kodi/userdata/`
- **Elementum Settings**: `~/.kodi/userdata/addon_data/plugin.video.elementum/`
- **Downloads**: `~/Downloads/Elementum/`
- **API Config**: `~/.kodi/userdata/advancedsettings.xml`

### Web Interface Access
- **URL**: http://YOUR_PI_IP:8080
- **Username**: kodi
- **Password**: kodi

### API Endpoints
- **JSON-RPC**: http://YOUR_PI_IP:8080/jsonrpc
- **Web Interface**: http://YOUR_PI_IP:8080/
- **WebSocket**: ws://YOUR_PI_IP:9090/

## 🔍 Testing Setup

### Test API Connectivity
```bash
python3 ~/kodi-homeassistant/test-kodi-api.py
```

### Test Remote Control
1. Open web browser to: http://YOUR_PI_IP:8080
2. Login with kodi/kodi
3. Try controlling playback

### Test Mobile Apps
1. Install Kore or Yatse
2. Connect using Pi IP, port 8080, user kodi, password kodi
3. Browse library and test controls

## 🚨 Troubleshooting

### Common Issues
1. **Can't connect remotely**:
   - Check if Kodi web server is enabled in settings
   - Verify firewall allows port 8080
   - Confirm username/password

2. **Elementum not working**:
   - Check downloads folder permissions
   - Verify BitTorrent ports aren't blocked
   - Check available disk space

3. **Home Assistant can't find Kodi**:
   - Verify IP address in configuration
   - Check Home Assistant can reach Pi IP
   - Confirm Kodi web interface is accessible

### Logs and Diagnostics
```bash
# Kodi logs
tail -f ~/.kodi/temp/kodi.log

# Test network connectivity
python3 ~/kodi-homeassistant/test-kodi-api.py

# Check running services
systemctl status kodi-standalone

# Monitor Elementum downloads
watch -n 5 "ls -la ~/Downloads/Elementum/"
```

## 🎯 Advanced Features

### Custom Scripts
Create your own automation scripts using the CLI:

```bash
#!/bin/bash
# Movie night automation
echo "Starting movie night mode..."

# Dim lights via Home Assistant (if available)
curl -X POST -H "Authorization: Bearer YOUR_HA_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"entity_id": "light.living_room"}' \
     http://YOUR_HA_IP:8123/api/services/light/turn_off

# Set Kodi volume
python3 ~/kodi-cli.py volume 60

# Show notification
python3 ~/kodi-cli.py notify "Movie Night" "Enjoy the show!"
```

### Integration with Other Services
- **Plex**: Use Plex for Kodi addon
- **Netflix**: Use unofficial Netflix addons
- **YouTube**: Built-in YouTube addon
- **Spotify**: Use Spotify for Kodi addon

This advanced setup gives you complete control over your Kodi installation with modern remote control capabilities! 🚀
