# RaspiCommandCenter - Complete Setup Guide

**Version:** 2.0.0  
**Target:** Raspberry Pi 5 with NVME SSD  
**Purpose:** Complete entertainment center and file sharing system

## System Overview

RaspiCommandCenter creates a comprehensive Raspberry Pi 5 system with:

- **Retro Gaming:** EmulationStation with 50+ emulator cores and automatic controller support
- **Media Center:** Kodi with Elementum plugin for torrent streaming and Home Assistant integration
- **Smart Home Hub:** Home Assistant Supervised for IoT device management
- **File Sharing:** Samba NAS server with Webmin web management
- **Performance:** Optimized hardware configuration with NVME SSD support

## Quick Start

### 🤖 FULLY AUTOMATED SETUP (Recommended)
```bash
sudo ./start.sh
# That's it! Everything installs automatically
# Reboot when prompted to complete setup
```

### The automated setup includes:
- **System Foundation:** Dependencies, performance optimization, services
- **Home Assistant Supervised:** Smart home platform
- **EmulationStation:** Complete retro gaming platform
- **Safe Configuration:** Conservative settings that won't break your system

## Complete System Features

### Gaming Platform
- **EmulationStation** with automatic controller detection
- **50+ Emulator Cores** for all major retro systems
- **ROM Organization** in `~/ROMs/<system>/` structure
- **Seamless Integration** with Kodi media center

### Media Center
- **Kodi 20.x** with optimized Raspberry Pi configuration
- **Elementum Plugin** for torrent streaming integration
- **Automatic Library Setup** for Movies, TV Shows, Music
- **Home Assistant Integration** for smart home control
- **CLI Management Tools** for remote operation

### Smart Home Hub
- **Home Assistant Supervised** (containerized deployment)
- **Device Discovery** and integration
- **Automation Platform** for IoT devices
- **Web Interface** at `http://[PI-IP]:8123`

### File Sharing & NAS
- **Samba File Server** for cross-platform sharing
- **Webmin Management** interface at `http://[PI-IP]:10000`
- **Home Directory Sharing** with organized folder structure
- **Network Discovery** (Windows/macOS/Linux/mobile compatible)
- **Secure Authentication** with user-based access control

## System Architecture

### Directory Structure
```
RaspiCommandCenter/
├── start.sh              # Phase 1: System preparation
├── scripts/               # Setup scripts
│   ├── phase2.sh         # Core applications launcher
│   ├── setup_homeassistant.sh
│   ├── setup_emulationstation.sh
│   ├── setup_kodi.sh     # Enhanced media center
│   └── setup_nas_fileserver.sh
├── utils/                # Shared utilities
│   ├── logging.sh        # Logging functions
│   └── common.sh         # Common functions
├── docs/                 # Documentation
└── logs/                 # Installation logs
```

### Media Directory Structure
```
~/
├── Videos/
│   ├── Movies/           # Auto-configured in Kodi
│   └── TV Shows/         # Auto-configured in Kodi
├── Music/                # Auto-configured in Kodi
├── ROMs/                 # Organized by system
│   ├── nes/
│   ├── snes/
│   ├── psx/
│   └── [50+ systems]/
├── Downloads/            # Shared download folder
├── Documents/            # Document sharing
└── Pictures/             # Photo sharing
```

## Network Services

### Web Interfaces
- **Home Assistant:** `http://[PI-IP]:8123`
- **Webmin (NAS Management):** `http://[PI-IP]:10000`
- **Kodi Web Interface:** `http://[PI-IP]:8080` (when enabled)

### File Sharing Access
- **Windows:** `\\[PI-IP]` or `\\[PI-HOSTNAME]`
- **macOS:** `smb://[PI-IP]` or Finder > Network
- **Linux:** `smb://[PI-IP]` or file manager network locations
- **Mobile:** ES File Explorer, FX File Explorer, or similar apps

## Hardware Optimization

### Performance Features
- **CPU Overclock:** 3.0 GHz (from 2.4 GHz)
- **GPU Overclock:** 1.0 GHz (from 800 MHz)
- **NVME Support:** PCIe Gen 3 enabled for fast storage
- **Memory Optimization:** GPU memory split and cache settings
- **4K Video:** Hardware acceleration enabled

### Cooling & Power
- **Fan Control:** Automatic temperature-based fan curves
- **Thermal Management:** Optimized for sustained performance
- **Power Efficiency:** Balanced performance and power consumption

## Setup Process

### Phase 1: System Preparation (Required)
1. **Hardware Detection** and compatibility checks
2. **System Updates** and essential packages
3. **Boot Configuration** for NVME and overclocking
4. **Service Configuration** (SSH, Docker, networking)
5. **Performance Optimization** settings

**Result:** Optimized Raspberry Pi OS foundation  
**Reboot Required:** Yes

### Phase 2: Core Applications (Recommended)
1. **Home Assistant Supervised** installation
2. **EmulationStation + RetroPie** complete gaming platform
3. **Controller Detection** and automatic configuration
4. **ROM Directory** structure creation

**Result:** Functional gaming and smart home system  
**Reboot Required:** No

### Phase 3: Optional Features (As Needed)
1. **Enhanced Kodi** with Elementum and automation
2. **NAS File Server** with web management
3. **Media Library** auto-configuration
4. **Advanced Integration** features

**Result:** Complete entertainment and file sharing system  
**Reboot Required:** Only for NAS server

## Management Tools

### CLI Tools (after Kodi setup)
```bash
# Kodi control
kodi-cli start|stop|restart|status
kodi-scan-library

# Home Assistant integration
ha-toggle-kodi            # Switch between Kodi and EmulationStation
```

### NAS Management (after NAS setup)
```bash
# NAS control
nas-manager.sh status|start|stop|restart|users|shares|logs
nas-info.sh               # Display connection information
```

### System Monitoring
```bash
# Performance monitoring
htop                      # System resources
vcgencmd measure_temp     # CPU temperature
vcgencmd measure_clock arm # CPU frequency
```

## Troubleshooting

### Common Issues

**EmulationStation won't start:**
- Check if system was rebooted after Phase 1
- Verify graphics driver: `sudo raspi-config` > Advanced > GL Driver > Legacy

**Kodi playback issues:**
- Ensure 4K acceleration is enabled in Phase 1
- Check GPU memory split: `vcgencmd get_mem gpu`

**Network file sharing not working:**
- Verify Samba is running: `sudo systemctl status smbd`
- Check firewall: `sudo ufw status`
- Confirm network discovery: `sudo systemctl status wsdd avahi-daemon`

**Performance issues:**
- Monitor temperatures: `vcgencmd measure_temp`
- Check overclock settings in `/boot/config.txt`
- Verify NVME is detected: `lsblk`

### Log Locations
- **Setup Logs:** `~/RaspiCommandCenter/logs/`
- **System Logs:** `sudo journalctl -u [service-name]`
- **Kodi Logs:** `~/.kodi/temp/kodi.log`
- **Home Assistant Logs:** `sudo docker logs homeassistant`

## System Requirements

### Hardware (Recommended)
- **Raspberry Pi 5** (4GB+ RAM recommended)
- **NVME SSD** (PCIe HAT required)
- **Active Cooling** (fan HAT or case with fan)
- **Quality Power Supply** (27W+ official adapter)
- **Fast SD Card** (Class 10 U3 minimum for OS)

### Network
- **Ethernet Connection** recommended for NAS performance
- **Wi-Fi 6** supported for wireless setup
- **Local Network** with DHCP for automatic IP assignment

### Controllers (Gaming)
- **USB Controllers** (Xbox, PlayStation, generic HID)
- **Bluetooth Controllers** (PS4, PS5, Xbox wireless)
- **Retro Controllers** (8BitDo, Buffalo Classic, etc.)

## Security Considerations

### Default Security
- **SSH enabled** with key-based authentication recommended
- **Firewall configured** for necessary services only
- **User authentication** required for file sharing
- **Automatic updates** enabled for security patches

### Hardening Recommendations
1. **Change default passwords** for all services
2. **Disable SSH password** authentication (use keys)
3. **Configure VPN** for remote access
4. **Package list updates only** via `sudo apt update` (NEVER run `sudo apt upgrade` - it breaks Pi systems!)
5. **Monitor logs** for unusual activity

## System Stability & Safety

### ⚠️ CRITICAL: Never Run These Commands
- **`sudo apt upgrade`** - Will break drivers and firmware
- **`sudo rpi-update`** - Will install unstable firmware
- **`sudo rpi-eeprom-update -a`** - Can brick the boot process

### ✅ Safe Maintenance
- **`sudo apt update`** - Safe (updates package lists only)
- **Install new packages** - Safe (doesn't modify existing drivers)
- **Manual configuration** - Safe when done carefully

## Advanced Configuration

### Custom ROM Collections
- Place ROM files in appropriate `~/ROMs/<system>/` folders
- EmulationStation will automatically detect and configure
- Supported formats vary by emulator core
- Legal ROM sources: homebrew, personal backups, open-source games

### Media Library Customization
- **Movies:** Place files in `~/Videos/Movies/`
- **TV Shows:** Organize as `~/Videos/TV Shows/[Show Name]/Season X/`
- **Music:** Support for MP3, FLAC, M4A, OGG formats
- **Metadata:** Kodi will automatically scrape information

### Home Assistant Integration
- **Device Discovery:** Automatic detection of network devices
- **Automation Examples:** Turn on Kodi when motion detected
- **Voice Control:** Integration with Alexa, Google Assistant
- **Mobile App:** Home Assistant Companion app

### Performance Tuning
- **Overclocking:** Adjust values in `/boot/config.txt`
- **Memory Split:** Modify `gpu_mem` for graphics performance
- **Network:** Optimize Samba settings for faster file transfers
- **Storage:** Use high-quality NVME SSD for best performance

## Support Resources

### Documentation
- **Setup Logs:** Check `logs/` directory for detailed information
- **System Status:** Use provided CLI tools for diagnostics
- **Configuration Files:** Most settings accessible via scripts

### Community
- **RetroPie Forums:** For gaming-related questions
- **Home Assistant Community:** For smart home integration
- **Raspberry Pi Forums:** For hardware and OS issues

### Professional Support
- Consider professional installation for complex network environments
- Hardware assembly assistance available from Pi specialists
- Custom configuration services for specific requirements

---

**RaspiCommandCenter** provides a complete, modular, and maintainable solution for transforming your Raspberry Pi 5 into a powerful entertainment center and file sharing system. Each component is designed to work independently or as part of the complete system, giving you flexibility in deployment and customization.
