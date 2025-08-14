# RaspiCommandCenter - Web Services Quick Reference

## 🌐 Access Your Services

Once your RaspiCommandCenter is set up, access these web interfaces from any device on your network:

### Find Your Pi's IP Address
```bash
# On the Pi, run:
hostname -I

# Or check your router's device list for "raspberrypi"
```

### Web Service URLs

Replace `[PI-IP]` with your Raspberry Pi's actual IP address:

#### 🏠 **Home Assistant** (Smart Home Hub)
- **URL**: `http://[PI-IP]:8123`
- **Purpose**: Smart home control, automation, device management
- **Default Access**: Create admin account on first visit
- **Mobile**: Install "Home Assistant Companion" app

#### 🎬 **Kodi Web Interface** (Media Center)
- **URL**: `http://[PI-IP]:8080`
- **Purpose**: Remote control Kodi, browse media library, stream content
- **Setup**: Available after running `./scripts/setup_kodi.sh`
- **Mobile**: Use "Kore" official Kodi remote app

#### 💾 **Webmin** (NAS File Server Management)
- **URL**: `http://[PI-IP]:10000`
- **Purpose**: File server management, user accounts, system administration
- **Setup**: Available after running `./scripts/setup_nas_fileserver.sh`
- **Login**: Use your Pi username and password

### 📂 File Sharing Access

#### Windows
- Open File Explorer
- Type in address bar: `\\[PI-IP]` or `\\raspberrypi`
- Or browse Network > WORKGROUP > RASPBERRYPI

#### macOS
- Open Finder
- Press Cmd+K or Go > Connect to Server
- Type: `smb://[PI-IP]` or `smb://raspberrypi.local`

#### Linux
- Open file manager
- Navigate to "Other Locations" or "Network"
- Type: `smb://[PI-IP]` or browse network

#### Mobile (Android/iOS)
- Install file manager with SMB support:
  - **ES File Explorer** (Android)
  - **FX File Explorer** (Android/iOS)
  - **FileBrowser** (iOS)
- Add network location: `smb://[PI-IP]`

### 🎮 Gaming Access

#### EmulationStation
- **Physical Access**: Boots automatically with boot configuration
- **Command Line**: Type `emulationstation` in terminal
- **Remote**: Use SSH to start/stop: `ssh pi@[PI-IP]`

#### RetroArch Web Interface (Advanced)
- **URL**: `http://[PI-IP]:8080/retroarch` (if enabled)
- **Purpose**: Advanced emulator configuration
- **Note**: Requires manual RetroArch web server configuration

### 🛠️ System Management

#### SSH Access
```bash
# From another computer:
ssh pi@[PI-IP]
# or
ssh pi@raspberrypi.local
```

#### VNC (Desktop Access)
- Enable via: `sudo raspi-config` > Interface Options > VNC
- **URL**: Use VNC Viewer app with `[PI-IP]:5900`

### 📱 Recommended Mobile Apps

#### Home Automation
- **Home Assistant Companion** (Official HA app)
- **Kore** (Official Kodi remote)

#### File Management
- **ES File Explorer** (Android)
- **FileBrowser** (iOS)
- **FX File Explorer** (Android/iOS)

#### Remote Access
- **VNC Viewer** (Remote desktop)
- **Termius** or **JuiceSSH** (SSH clients)

### 🔒 Security Notes

#### Default Ports
- `8123` - Home Assistant (HTTP)
- `8080` - Kodi Web Interface (HTTP)
- `10000` - Webmin (HTTPS/HTTP)
- `445` - Samba file sharing (SMB)
- `22` - SSH access

#### Firewall
RaspiCommandCenter automatically configures firewall rules for these services. To check:
```bash
sudo ufw status
```

#### Password Security
- **Change default passwords** for all services
- **Use strong passwords** for Webmin and file sharing
- **Consider SSH key authentication** instead of passwords

### 🚀 Performance Tips

#### For Best Web Interface Performance
- Use **Ethernet connection** when possible
- **Modern web browser** (Chrome, Firefox, Safari, Edge)
- **Same network** as the Pi for fastest access

#### For File Sharing Performance
- **Gigabit Ethernet** provides best speeds
- **Wi-Fi 6** (802.11ax) recommended for wireless
- **Quality network equipment** (router, switches)

### 📋 Quick Connection Test

To verify all services are running:

```bash
# On the Pi, check service status:
sudo systemctl status homeassistant
sudo systemctl status kodi
sudo systemctl status smbd
sudo systemctl status webmin

# Check which ports are listening:
sudo netstat -tlnp | grep ':8123\|:8080\|:10000\|:445'
```

### 🆘 Troubleshooting

#### Can't Access Web Services
1. **Check IP address**: `hostname -I`
2. **Check firewall**: `sudo ufw status`
3. **Check services**: `sudo systemctl status [service-name]`
4. **Try different browser** or **clear browser cache**

#### File Sharing Not Working
1. **Check Samba**: `sudo systemctl status smbd`
2. **Check network discovery**: `sudo systemctl status wsdd avahi-daemon`
3. **Try IP address** instead of hostname
4. **Check username/password**

#### Slow Performance
1. **Use Ethernet** instead of Wi-Fi
2. **Check network speed**: `speedtest-cli`
3. **Monitor system resources**: `htop`
4. **Check temperature**: `vcgencmd measure_temp`

---

**Bookmark this page** and keep your Pi's IP address handy for easy access to all services!
