#!/bin/bash

# Simple NAS File Server Setup (Samba only)
# Clean, focused file sharing for media directories

set -euo pipefail

USER="$USER"
auto_mode=false

# Parse command line arguments
if [[ "${1:-}" == "--auto" ]]; then
    auto_mode=true
fi

echo "=== Setting up NAS File Server ==="

# Install Samba
echo "Installing Samba..."
sudo apt update > /dev/null 2>&1
sudo apt install -y samba samba-common-bin > /dev/null 2>&1

# Create media directories if they don't exist
echo "Creating media directories..."
mkdir -p "$HOME"/{Videos,Music,Pictures,Downloads,ROMs}

# Backup original config
if [[ -f /etc/samba/smb.conf ]]; then
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
fi

# Create simple Samba configuration for local network access
echo "Configuring Samba shares (open local network access)..."
sudo tee /etc/samba/smb.conf > /dev/null << EOF
[global]
   workgroup = WORKGROUP
   server string = Pi Media Server
   security = user
   map to guest = bad user
   guest account = nobody
   dns proxy = no
   socket options = TCP_NODELAY
   max protocol = SMB3
   min protocol = SMB2
   
   # Local network access - no authentication required
   hosts allow = 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 127.0.0.1
   hosts deny = 0.0.0.0/0

[Videos]
   comment = Movies and TV Shows
   path = $HOME/Videos
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $USER

[Music]
   comment = Music Library
   path = $HOME/Music
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $USER

[Pictures]
   comment = Photos and Images
   path = $HOME/Pictures
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $USER

[ROMs]
   comment = Gaming ROMs and Emulation
   path = $HOME/ROMs
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $USER

[Downloads]
   comment = Downloads and Files
   path = $HOME/Downloads
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $USER
EOF

# Test configuration
if ! sudo testparm -s > /dev/null 2>&1; then
    echo "ERROR: Samba configuration is invalid"
    exit 1
fi

# No Samba user setup needed - using guest access for local network
echo "Configuring guest access for local network..."
# Enable nobody account for guest access
sudo useradd -r -s /bin/false nobody 2>/dev/null || true

# Start services
echo "Starting Samba services..."
sudo systemctl enable smbd nmbd > /dev/null 2>&1
sudo systemctl restart smbd nmbd

# Simple firewall rules
if command -v ufw > /dev/null 2>&1; then
    sudo ufw allow 139/tcp > /dev/null 2>&1  # NetBIOS
    sudo ufw allow 445/tcp > /dev/null 2>&1  # SMB
    sudo ufw allow 137/udp > /dev/null 2>&1  # NetBIOS Name
    sudo ufw allow 138/udp > /dev/null 2>&1  # NetBIOS Datagram
fi

echo ""
echo "=== NAS Setup Complete ==="
echo "✓ Samba file server running"
echo "✓ All media directories shared"
echo "✓ Open local network access (no passwords needed)"

if [[ "$auto_mode" == "false" ]]; then
    PI_IP=$(hostname -I | awk '{print $1}')
    echo ""
    echo "Access your files from local network:"
    echo "• Windows: \\\\$PI_IP"
    echo "• macOS/Linux: smb://$PI_IP"
    echo ""
    echo "Available shares (no password required):"
    echo "• Videos (Movies, TV Shows)"
    echo "• Music (Music Library)" 
    echo "• Pictures (Photos, Images)"
    echo "• ROMs (Gaming Files)"
    echo "• Downloads (Files, Torrents)"
    echo ""
    echo "Note: Access restricted to local network only"
fi
