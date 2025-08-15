# RaspiCommandCenter v2.1.0

## Complete All-in-One Raspberry Pi Entertainment System

Transform your Raspberry Pi 5 into a complete entertainment and automation hub with **one command**. After reboot, your Pi boots directly to a gaming console while running smart home and media services in the background.

✨ **v2.1.0 Features**: Rock-solid stability with zero logging errors, bulletproof script execution, and ultra-clean output for seamless installation experience.piCommandCenter v2.0.0

## Complete All-in-One Raspberry Pi Entertainment System

Transform your Raspberry Pi 5 into a complete entertainment and automation hub with **one command**. After reboot, your Pi boots directly to a gaming console while running smart home and media services in the background.

## System Components

### Gaming Console
- EmulationStation with 20+ retro gaming systems
- Automatic boot to gaming interface (no desktop)
- Controller auto-detection and configuration
- Comprehensive ROM directory structure

### Smart Home Hub
- Home Assistant Supervised with full Docker support
- Complete add-on ecosystem available
- Web-based automation and device control

### Media Center
- Kodi integrated with EmulationStation
- Elementum plugin for torrent streaming
- Automatic media library configuration

### Network File Server
- Open local network access (no passwords needed)
- All media folders shared: Videos, Music, Pictures, ROMs, Downloads
- Easy remote ROM management and media uploads

## Network Access

Access all services from any device on your local network:

- **Gaming**: Direct console access (auto-boots EmulationStation)
- **Home Assistant**: `http://[PI-IP]:8123`
- **Kodi Web Control**: `http://[PI-IP]:8080`
- **File Shares**: `\\[PI-IP]` (Windows) or `smb://[PI-IP]` (Mac/Linux)

Find your Pi's IP: `hostname -I` or check your router

## Quick Start

**Complete setup in one command:**

```bash
cd ~ && git clone https://github.com/VenomekPL/RaspiCommandCenter.git && cd RaspiCommandCenter && chmod +x *.sh scripts/*.sh && sudo ./start.sh
```

**What happens:**

1. Installs all system dependencies
2. Configures console boot (no desktop GUI)
3. Sets up EmulationStation autostart
4. Installs Home Assistant Supervised
5. Configures Kodi media center
6. Sets up network file sharing
7. Optimizes performance settings
8. **Prompts for reboot to activate everything**

## Requirements

- Raspberry Pi 5 (4GB or 8GB recommended)
- Fresh Raspberry Pi OS (64-bit) installation
- Internet connection
- MicroSD card (32GB+ recommended)
- Optional: NVME SSD for better performance

## After Installation

### First Boot Experience

1. **Boot**: Pi starts in console mode
2. **Login**: EmulationStation launches automatically
3. **Gaming**: Full retro gaming library ready
4. **Media**: Access Kodi from EmulationStation → Ports
5. **Smart Home**: Configure Home Assistant via web browser
6. **File Management**: Upload ROMs/media from any computer

### Adding ROMs

Upload ROM files to your Pi from any computer:

**Windows**: Open `\\[PI-IP]\ROMs` in File Explorer
**Mac**: Open `smb://[PI-IP]/ROMs` in Finder  
**Linux**: Open `smb://[PI-IP]/ROMs` in file manager

### Supported Gaming Systems

- Nintendo: NES, SNES, N64, GameCube, Wii, Game Boy, GBA, DS
- Sony: PlayStation 1, 2, PSP
- Sega: Master System, Genesis, Game Gear, Dreamcast
- Atari: 2600, 7800, Lynx
- Arcade: MAME, FinalBurn Neo
- And many more!

## System Architecture

### Automated Pipeline
```
start.sh → Phase 1 (System) → Phase 2 (Applications) → Reboot
```

### Phase 1: System Foundation
- `install_dependencies.sh`: Essential packages and Docker
- `configure_performance.sh`: Hardware optimization
- `configure_services.sh`: Console boot and EmulationStation autostart

### Phase 2: Applications
- `setup_homeassistant_supervised.sh`: Smart home platform
- `setup_emulationstation.sh`: Gaming system installation
- `configure_emulationstation.sh`: Complete gaming configuration
- `setup_kodi.sh`: Media center integration
- `setup_nas_fileserver.sh`: Network file sharing

## Advanced Usage

### Manual Script Execution

If you prefer granular control:

```bash
# System foundation
sudo ./scripts/install_dependencies.sh
sudo ./scripts/configure_performance.sh  
sudo ./scripts/configure_services.sh

# Reboot required
sudo reboot

# Applications
./scripts/phase2.sh
```

### Individual Components

Run specific components:

```bash
# Home Assistant only
sudo ./scripts/setup_homeassistant_supervised.sh

# Gaming setup only
sudo ./scripts/setup_emulationstation.sh

# NAS server only
sudo ./scripts/setup_nas_fileserver.sh
```

## Troubleshooting

### Common Issues

**EmulationStation doesn't start**: Check if console boot is configured
```bash
sudo systemctl get-default  # Should show: multi-user.target
```

**Can't access network shares**: Verify Samba is running
```bash
sudo systemctl status smbd
```

**Home Assistant not accessible**: Check Docker status
```bash
sudo docker ps
```

### Support

- Check logs: `~/logs/`
- View system status: `systemctl status`
- Test network connectivity: `ping [PI-IP]`

## Performance Optimization

### Hardware Recommendations

- **Cooling**: Active cooling recommended for sustained performance
- **Storage**: NVME SSD significantly improves loading times
- **Power**: Use official Pi 5 power adapter (5V/5A)
- **Network**: Wired Ethernet for best streaming performance

### Monitoring

Access system monitoring:
- **htop**: `htop` (CPU/Memory usage)
- **iotop**: `sudo iotop` (Disk I/O)
- **Network**: Home Assistant System tab

## License

MIT License - See LICENSE file for details

## Contributing

1. Fork the repository
2. Create feature branch
3. Test on fresh Pi installation
4. Submit pull request

## Changelog

### v2.1.0 - Ultra-Stable Release
- **Zero Runtime Errors**: Complete elimination of all logging function calls
- **Bulletproof Execution**: All 9 scripts now execute flawlessly without crashes
- **Clean Output**: Simple echo statements replace complex logging systems
- **Enhanced Reliability**: Thoroughly tested script execution pipeline
- **Performance Focus**: Reduced overhead from logging infrastructure

### v2.0.2 - Critical Runtime Fix
- Fixed configure_services.sh runtime errors on line 160
- Removed problematic logging function calls

### v2.0.1 - Function Cleanup
- Complete cleanup of removed functions and references
- Streamlined script architecture

### v2.0.0 - Major System Rewrite
- Complete system rewrite
- One-command installation
- Console boot with EmulationStation autostart
- Integrated NAS file server
- Network-based ROM management
- Clean, focused scripts (no logging spam)
- Full pipeline automation

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
