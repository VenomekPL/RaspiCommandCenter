# RaspiCommandCenter - Complete Smart Home & Media System

Transform your Raspberry Pi 5 with NVME SSD into a complete smart home and retro gaming media center with automatic EmulationStation boot.

## 🎯 What This Creates

- **Smart Home Hub**: Home Assistant Supervised with full add-on support
- **Retro Gaming Station**: EmulationStation with all major console emulators (auto-starts on boot)
- **Media Center**: Kodi with Elementum torrent streaming and automatic library setup
- **NAS File Server**: Samba + Webmin for complete home directory sharing
- **Command Line Boot**: Optimized resource usage with desktop-free operation
- **High Performance**: Optimized for NVME SSD and proper cooling

## 🌐 Web Services (Access from any device)

Once installed, access these services from any device on your network:

- **Home Assistant**: `http://[PI-IP]:8123` - Smart home control and automation
- **Kodi Web Interface**: `http://[PI-IP]:8080` - Remote media center control
- **Webmin (NAS Management)**: `http://[PI-IP]:10000` - File server web management

**Find your Pi's IP address**: `hostname -I` or check your router's device list

## 🛠️ Requirements

- Raspberry Pi 5 (4GB or 8GB recommended)
- NVME SSD HAT (M.2 HAT+ or compatible)
- Proper cooling solution (Pironman case or equivalent)
- Fresh Raspberry Pi OS (64-bit) installation
- Internet connection

## 🚀 Quick Start (Copy & Paste)

**Single command installation:**

```bash
cd ~ && git clone --depth=1 https://github.com/VenomekPL/RaspiCommandCenter.git && cd RaspiCommandCenter && chmod +x *.sh scripts/*.sh && sudo ./start.sh
```

**Or step-by-step:**

```bash
# Go to home directory
cd ~

# Clone the repository
git clone --depth=1 https://github.com/VenomekPL/RaspiCommandCenter.git

# Enter the directory
cd RaspiCommandCenter

# Make all scripts executable
chmod +x *.sh scripts/*.sh

# Run Phase 1 setup (requires reboot)
sudo ./start.sh
```

### Phase 1: System Preparation

```bash
sudo ./start.sh
```

🤖 **FULLY AUTOMATED**: This now runs everything automatically!
- System updates and essential packages
- NVME SSD configuration and boot optimization  
- Hardware acceleration setup (4K video support)
- Performance tuning and cooling integration
- Home Assistant Supervised installation
- EmulationStation with all retro gaming emulators
- **Automatic reboot when complete**

### Manual Execution (Advanced Users)

If you prefer granular control over each step:

```bash
# Phase 1: System Foundation
sudo ./scripts/install_dependencies.sh
sudo ./scripts/configure_performance.sh
sudo ./scripts/configure_services.sh

# Reboot required
sudo reboot

# Phase 2: Applications
./scripts/phase2.sh
```

## 🎮 What You Get

### Smart Home Control

- **Home Assistant Supervised**: Full smart home platform with add-ons
- **Web Interface**: Access at `http://[PI-IP]:8123`
- **Container-based**: Reliable, updatable, and secure

### Retro Gaming Paradise

- **EmulationStation**: Beautiful game launcher interface (auto-starts on boot)
- **All Major Consoles**: NES, SNES, Genesis, PlayStation, N64, Dreamcast, and more
- **Modern Systems**: PSP, Nintendo DS, experimental GameCube/Wii support
- **Bluetooth Controllers**: Xbox, PlayStation, and generic controller support
- **Command Line Boot**: No desktop overhead, maximum gaming performance

### Advanced Media Center

- **Kodi with Elementum**: 4K media center with torrent streaming
- **Automatic Library Setup**: Pre-configured Movies, TV Shows, Music folders
- **Home Assistant Integration**: Smart control and automation
- **Web Interface**: Remote control at `http://[PI-IP]:8080`

### NAS File Server

- **Samba File Sharing**: Access from Windows, macOS, Linux, mobile
- **Webmin Management**: Web interface at `http://[PI-IP]:10000`
- **Complete Home Sharing**: Videos, Music, ROMs, Downloads, Documents
- **Network Discovery**: Automatic device detection across platforms

### Performance Optimization

- **Command Line Boot**: No desktop resources, faster startup
- **EmulationStation Auto-start**: Gaming ready immediately after boot
- **Helper Scripts**: Easy desktop access when needed (`~/start-desktop.sh`)
- **Resource Efficiency**: Maximum performance for gaming and media

## 📁 Project Structure

```text
RaspiCommandCenter/
├── start.sh                    # Phase 1: Main orchestrator script
├── phase2.sh                   # Phase 2: Application installer
├── requirements.txt            # Essential system packages
├── scripts/
│   ├── install_dependencies.sh    # Modular: System packages & Docker
│   ├── configure_performance.sh   # Modular: Overclocking & optimization  
│   ├── configure_services.sh      # Modular: System services & network
│   ├── setup_homeassistant.sh     # Home Assistant Supervised installer
│   └── setup_emulationstation.sh  # RetroPie + Kodi integration
├── utils/
│   ├── logging.sh              # Logging utilities
│   └── common.sh               # Shared functions
├── docs/                       # Additional documentation
└── logs/                       # Installation logs & reports
```

## 🔧 Modular Architecture

The setup is now **fully modular** for easy maintenance and customization:

### Phase 1 Modules:
- **`install_dependencies.sh`**: System updates, essential packages, Docker
- **`configure_performance.sh`**: 3GHz CPU, 1GHz GPU, NVME optimization  
- **`configure_services.sh`**: SSH, Bluetooth, audio, network services

### Phase 2 Applications:
- **`setup_homeassistant.sh`**: Complete Home Assistant Supervised setup
- **`setup_emulationstation.sh`**: Full RetroPie + seamless Kodi integration

## 🔧 Manual Configuration

### After Installation

1. **Home Assistant**: Configure at `http://[PI-IP]:8123`
2. **Add ROMs**: Place ROM files in `~/RetroPie/roms/<system>/`
3. **Controller Setup**: Pair Bluetooth controllers when prompted
4. **Kodi Access**: Available in EmulationStation's "Ports" menu
5. **File Sharing**: Access via `\\[PI-IP]` (Windows) or `smb://[PI-IP]` (macOS/Linux)

### Boot Configuration (Optional)

For optimal gaming performance, configure command line boot:

```bash
# Configure boot to command line + EmulationStation auto-start
./scripts/configure_boot_cli.sh
```

**What this does:**
- Boots directly to command line (no desktop overhead)
- Auto-starts EmulationStation after login
- Exit EmulationStation returns to command line
- Helper scripts for desktop access when needed

### Useful Commands

```bash
# Gaming
emulationstation              # Start EmulationStation
~/restart-es.sh              # Quick EmulationStation restart

# Media & Services
kodi                         # Start Kodi directly
kodi-cli start|stop|restart  # Control Kodi service (after setup_kodi.sh)

# System Management
~/start-desktop.sh           # Start desktop when needed (after boot config)
nas-manager.sh status        # Check NAS file server status
~/system-info.sh             # System information

# Configuration
cd ~/RetroPie-Setup && sudo ./retropie_setup.sh  # RetroPie settings
```

### Web Interface Access

All web services are accessible from any device on your network:

- **Home Assistant**: `http://[PI-IP]:8123` - Smart home dashboard
- **Kodi Web Remote**: `http://[PI-IP]:8080` - Media center control
- **Webmin (NAS)**: `http://[PI-IP]:10000` - File server management

**Pro Tip**: Bookmark these URLs on your phone/tablet for easy access!

## 🎯 Hardware Optimization

- **NVME Gen 3**: Automatically configured for maximum speed
- **4K Video**: Hardware-accelerated HEVC decoding
- **Cooling**: Integrated fan control and temperature monitoring
- **Performance**: CPU governor and memory optimization
- **Bluetooth**: Xbox controller compatibility patches

## 📖 Additional Documentation

- [Detailed Hardware Setup](docs/raspigeneral.md)
- [Gaming Configuration](docs/raspigaming.md)  
- [Media Server Guide](docs/raspimediaserver.md)

## 🐛 Troubleshooting

- **No NVME detected**: Check PCIe connection and boot config
- **Controllers not pairing**: Disable ERTM with included fix
- **4K video issues**: Verify HDMI 2.0 cable and TV compatibility
- **Permission errors**: Ensure scripts are executable with `chmod +x`

## 📜 License

MIT License - Feel free to modify and distribute
