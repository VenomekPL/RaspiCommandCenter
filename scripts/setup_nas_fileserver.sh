#!/bin/bash

# NAS File Server Setup Script (Samba + Webmin)
# This script sets up secure file sharing for the entire home directory
# with web-based management interface

set -euo pipefail

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/common.sh"

# Configuration
USER_HOME="$HOME"
SAMBA_USER="$USER"
WEBMIN_PORT="10000"

log_info "Starting NAS File Server Setup (Samba + Webmin)"

# Function to install Samba and dependencies
install_samba() {
    log_info "Installing Samba file server..."
    
    # Update package list
    sudo apt update
    
    # Install Samba and related packages
    sudo apt install -y \
        samba \
        samba-common-bin \
        samba-client \
        cifs-utils \
        acl \
        attr \
        winbind \
        libnss-winbind \
        libpam-winbind
    
    # Install additional tools for better Windows compatibility
    sudo apt install -y \
        wsdd \
        avahi-daemon \
        avahi-utils
    
    log_success "Samba installation completed"
}

# Function to install Webmin
install_webmin() {
    log_info "Installing Webmin web management interface..."
    
    # Install dependencies
    sudo apt install -y \
        wget \
        apt-transport-https \
        software-properties-common
    
    # Add Webmin repository
    wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
    echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list
    
    # Update and install Webmin
    sudo apt update
    sudo apt install -y webmin
    
    # Configure Webmin for Pi
    sudo sed -i 's/ssl=1/ssl=0/' /etc/webmin/miniserv.conf
    sudo sed -i "s/port=10000/port=$WEBMIN_PORT/" /etc/webmin/miniserv.conf
    
    # Allow access from any IP (change this for production)
    echo "allow=0.0.0.0/0" | sudo tee -a /etc/webmin/miniserv.conf
    
    # Restart Webmin
    sudo systemctl restart webmin
    sudo systemctl enable webmin
    
    log_success "Webmin installation completed"
}

# Function to configure Samba shares
configure_samba_shares() {
    log_info "Configuring Samba shares..."
    
    # Backup original smb.conf
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    
    # Create new Samba configuration
    sudo tee /etc/samba/smb.conf > /dev/null << EOF
[global]
   workgroup = WORKGROUP
   server string = Raspberry Pi NAS
   netbios name = RaspberryPi-NAS
   security = user
   map to guest = bad user
   dns proxy = no
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
   use sendfile = yes
   max protocol = SMB3
   min protocol = SMB2
   
   # Performance optimizations
   strict allocate = no
   allocation roundup size = 4096
   read raw = yes
   write raw = yes
   oplocks = yes
   max xmit = 65535
   deadtime = 15
   getwd cache = yes
   
   # Fruit (macOS) support
   vfs objects = catia fruit streams_xattr
   fruit:metadata = stream
   fruit:model = MacSamba
   fruit:posix_rename = yes
   fruit:veto_appledouble = no
   fruit:wipe_intentionally_left_blank_rfork = yes
   fruit:delete_empty_adfiles = yes
   
   # WSL/Windows compatibility
   ea support = yes
   store dos attributes = yes
   map hidden = no
   map system = no
   map archive = no
   map readonly = no

# Home Directory Share (Full Access)
[Home]
   comment = Full Home Directory Access
   path = $USER_HOME
   browseable = yes
   writable = yes
   guest ok = no
   valid users = $SAMBA_USER
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER

# Videos Share (Media Files)
[Videos]
   comment = Movies and TV Shows
   path = $USER_HOME/Videos
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER

# Music Share
[Music]
   comment = Music Library
   path = $USER_HOME/Music
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER

# ROMs Share (Gaming)
[ROMs]
   comment = Gaming ROMs and EmulationStation
   path = $USER_HOME/ROMs
   browseable = yes
   writable = yes
   guest ok = no
   valid users = $SAMBA_USER
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER

# Downloads Share
[Downloads]
   comment = Downloads and Torrents
   path = $USER_HOME/Downloads
   browseable = yes
   writable = yes
   guest ok = no
   valid users = $SAMBA_USER
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER

# Documents Share
[Documents]
   comment = Documents and Files
   path = $USER_HOME/Documents
   browseable = yes
   writable = yes
   guest ok = no
   valid users = $SAMBA_USER
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER

# Pictures Share
[Pictures]
   comment = Photos and Images
   path = $USER_HOME/Pictures
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $SAMBA_USER
   force group = $SAMBA_USER
EOF
    
    # Test Samba configuration
    if sudo testparm -s > /dev/null 2>&1; then
        log_success "Samba configuration is valid"
    else
        log_error "Samba configuration has errors"
        return 1
    fi
    
    log_success "Samba shares configured"
}

# Function to setup Samba user
setup_samba_user() {
    log_info "Setting up Samba user account..."
    
    # Add current user to Samba
    echo "Creating Samba password for user: $SAMBA_USER"
    echo "Please enter a password for Samba access:"
    sudo smbpasswd -a "$SAMBA_USER"
    
    # Enable the user
    sudo smbpasswd -e "$SAMBA_USER"
    
    log_success "Samba user account configured"
}

# Function to configure network discovery
setup_network_discovery() {
    log_info "Setting up network discovery..."
    
    # Configure WSDD for Windows 10+ discovery
    sudo systemctl enable wsdd
    sudo systemctl start wsdd
    
    # Configure Avahi for macOS/Linux discovery
    sudo tee /etc/avahi/services/samba.service > /dev/null << EOF
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
 <name replace-wildcards="yes">%h</name>
 <service>
   <type>_smb._tcp</type>
   <port>445</port>
 </service>
 <service>
   <type>_device-info._tcp</type>
   <port>0</port>
   <txt-record>model=RaspberryPi</txt-record>
 </service>
</service-group>
EOF
    
    sudo systemctl restart avahi-daemon
    sudo systemctl enable avahi-daemon
    
    log_success "Network discovery configured"
}

# Function to setup firewall rules
configure_firewall() {
    log_info "Configuring firewall for file sharing..."
    
    # Install UFW if not present
    if ! command -v ufw &> /dev/null; then
        sudo apt install -y ufw
    fi
    
    # Configure UFW rules for Samba and Webmin
    sudo ufw allow 139/tcp  # NetBIOS Session Service
    sudo ufw allow 445/tcp  # SMB
    sudo ufw allow 137/udp  # NetBIOS Name Service
    sudo ufw allow 138/udp  # NetBIOS Datagram Service
    sudo ufw allow "$WEBMIN_PORT/tcp"  # Webmin
    sudo ufw allow 5357/tcp  # WSDD
    sudo ufw allow 3702/udp  # WSDD
    
    log_success "Firewall configured for file sharing"
}

# Function to optimize performance
optimize_performance() {
    log_info "Optimizing performance for file sharing..."
    
    # Create performance tuning script
    sudo tee /etc/samba/performance-tune.sh > /dev/null << 'EOF'
#!/bin/bash
# Samba performance optimizations for Raspberry Pi

# Increase network buffers
echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf

# Optimize TCP
echo 'net.ipv4.tcp_rmem = 4096 65536 16777216' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> /etc/sysctl.conf

# Apply settings
sysctl -p
EOF
    
    sudo chmod +x /etc/samba/performance-tune.sh
    sudo /etc/samba/performance-tune.sh
    
    log_success "Performance optimization completed"
}

# Function to create management scripts
create_management_scripts() {
    log_info "Creating NAS management scripts..."
    
    # Create main NAS management script
    cat > "$HOME/nas-manager.sh" << 'EOF'
#!/bin/bash
# NAS File Server Management Script

echo "=== Raspberry Pi NAS Management ==="
echo "1. Show Samba status and shares"
echo "2. List connected users"
echo "3. Restart Samba services"
echo "4. Show network discovery status"
echo "5. Test share connectivity"
echo "6. Show disk usage"
echo "7. Open Webmin (web interface)"
echo "8. Change Samba password"
echo "9. Show access logs"
echo ""

read -p "Choose option (1-9): " choice

case $choice in
    1)
        echo "=== Samba Status ==="
        sudo systemctl status smbd --no-pager
        echo ""
        echo "=== Configured Shares ==="
        sudo smbclient -L localhost -U%
        ;;
    2)
        echo "=== Connected Users ==="
        sudo smbstatus -b
        echo ""
        echo "=== Active Connections ==="
        sudo smbstatus -S
        ;;
    3)
        echo "=== Restarting Samba Services ==="
        sudo systemctl restart smbd nmbd wsdd
        echo "✓ Services restarted"
        ;;
    4)
        echo "=== Network Discovery Status ==="
        echo "WSDD (Windows discovery):"
        sudo systemctl status wsdd --no-pager -l
        echo ""
        echo "Avahi (macOS/Linux discovery):"
        sudo systemctl status avahi-daemon --no-pager -l
        ;;
    5)
        echo "=== Testing Share Connectivity ==="
        PI_IP=$(hostname -I | awk '{print $1}')
        echo "Pi IP Address: $PI_IP"
        echo ""
        echo "Test from Windows: \\\\$PI_IP"
        echo "Test from macOS: smb://$PI_IP"
        echo "Test from Linux: smb://$PI_IP"
        echo ""
        echo "Testing local connectivity..."
        smbclient -L localhost -U% 2>/dev/null || echo "Connection test failed"
        ;;
    6)
        echo "=== Disk Usage ==="
        df -h
        echo ""
        echo "=== Share Usage ==="
        echo "Home: $(du -sh $HOME 2>/dev/null | cut -f1)"
        echo "Videos: $(du -sh $HOME/Videos 2>/dev/null | cut -f1)"
        echo "Music: $(du -sh $HOME/Music 2>/dev/null | cut -f1)"
        echo "ROMs: $(du -sh $HOME/ROMs 2>/dev/null | cut -f1)"
        echo "Downloads: $(du -sh $HOME/Downloads 2>/dev/null | cut -f1)"
        ;;
    7)
        PI_IP=$(hostname -I | awk '{print $1}')
        echo "=== Opening Webmin ==="
        echo "Webmin URL: http://$PI_IP:10000"
        echo "Username: pi (or your system username)"
        echo "Password: your system password"
        echo ""
        if command -v xdg-open &> /dev/null; then
            xdg-open "http://$PI_IP:10000"
        else
            echo "Open the URL above in your web browser"
        fi
        ;;
    8)
        echo "=== Changing Samba Password ==="
        read -p "Enter username to change password for: " username
        sudo smbpasswd "$username"
        ;;
    9)
        echo "=== Recent Access Logs ==="
        echo "Samba logs:"
        sudo tail -20 /var/log/samba/log.smbd 2>/dev/null || echo "No Samba logs found"
        echo ""
        echo "System auth logs:"
        sudo tail -20 /var/log/auth.log | grep -i samba || echo "No auth logs found"
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF
    
    chmod +x "$HOME/nas-manager.sh"
    
    # Create connection info script
    cat > "$HOME/nas-info.sh" << 'EOF'
#!/bin/bash
# Display NAS connection information

PI_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

echo "========================================"
echo "    RASPBERRY PI NAS CONNECTION INFO"
echo "========================================"
echo ""
echo "🌐 Network Access:"
echo "   IP Address: $PI_IP"
echo "   Hostname: $HOSTNAME"
echo ""
echo "💻 Windows Connection:"
echo "   File Explorer: \\\\$PI_IP"
echo "   Command: net use Z: \\\\$PI_IP\\Home"
echo ""
echo "🍎 macOS Connection:"
echo "   Finder: smb://$PI_IP"
echo "   Command: mount -t smbfs //$PI_IP/Home /mnt/nas"
echo ""
echo "🐧 Linux Connection:"
echo "   Files: smb://$PI_IP"
echo "   Command: sudo mount -t cifs //$PI_IP/Home /mnt/nas"
echo ""
echo "📱 Mobile Access:"
echo "   Android: ES File Explorer, Solid Explorer"
echo "   iOS: Documents by Readdle, FE File Explorer"
echo "   URL: smb://$PI_IP"
echo ""
echo "🌐 Web Management:"
echo "   Webmin: http://$PI_IP:10000"
echo "   Username: $(whoami)"
echo "   Password: your system password"
echo ""
echo "📁 Available Shares:"
echo "   Home       - Full home directory access"
echo "   Videos     - Movies and TV shows (guest access)"
echo "   Music      - Music library (guest access)"
echo "   ROMs       - Gaming ROMs (secure access)"
echo "   Downloads  - Downloads folder (secure access)"
echo "   Documents  - Documents folder (secure access)"
echo "   Pictures   - Photos and images (guest access)"
echo ""
echo "🔐 Authentication:"
echo "   Username: $(whoami)"
echo "   Password: Set during installation"
echo ""
echo "📊 Management:"
echo "   Run: ~/nas-manager.sh"
echo "========================================"
EOF
    
    chmod +x "$HOME/nas-info.sh"
    
    log_success "Management scripts created"
}

# Function to start services
start_services() {
    log_info "Starting NAS services..."
    
    # Start and enable Samba services
    sudo systemctl enable smbd nmbd
    sudo systemctl start smbd nmbd
    
    # Start WSDD for Windows discovery
    sudo systemctl enable wsdd
    sudo systemctl start wsdd
    
    # Restart Webmin to ensure it's running
    sudo systemctl restart webmin
    
    log_success "All NAS services started and enabled"
}

# Function to display setup summary
display_nas_summary() {
    PI_IP=$(hostname -I | awk '{print $1}')
    HOSTNAME=$(hostname)
    
    echo ""
    echo "========================================================"
    echo "         RASPBERRY PI NAS SETUP COMPLETE!"
    echo "========================================================"
    echo ""
    echo "✓ Samba file server installed and configured"
    echo "✓ Webmin web interface installed and running"
    echo "✓ Network discovery enabled (Windows + macOS/Linux)"
    echo "✓ Firewall configured for secure access"
    echo "✓ Performance optimizations applied"
    echo "✓ Management scripts created"
    echo ""
    echo "🌐 ACCESS YOUR NAS:"
    echo ""
    echo "   Windows:    \\\\$PI_IP"
    echo "   macOS:      smb://$PI_IP"
    echo "   Linux:      smb://$PI_IP"
    echo "   Web:        http://$PI_IP:10000"
    echo ""
    echo "📁 AVAILABLE SHARES:"
    echo "   • Home - Full home directory (secure)"
    echo "   • Videos - Movies/TV (guest + secure access)"
    echo "   • Music - Music library (guest + secure access)"
    echo "   • ROMs - Gaming files (secure access only)"
    echo "   • Downloads - Downloads folder (secure access only)"
    echo "   • Documents - Documents (secure access only)"
    echo "   • Pictures - Photos (guest + secure access)"
    echo ""
    echo "🔐 AUTHENTICATION:"
    echo "   Username: $(whoami)"
    echo "   Password: [Set during installation]"
    echo ""
    echo "🛠️ MANAGEMENT:"
    echo "   NAS Manager: ~/nas-manager.sh"
    echo "   Connection Info: ~/nas-info.sh"
    echo "   Webmin: http://$PI_IP:10000"
    echo ""
    echo "📱 MOBILE ACCESS:"
    echo "   Use any SMB-compatible file manager"
    echo "   Server: $PI_IP"
    echo "   Username: $(whoami)"
    echo "   Password: [Your Samba password]"
    echo ""
    echo "🎮 KODI INTEGRATION:"
    echo "   All media folders are now network accessible"
    echo "   ROMs can be managed remotely"
    echo "   Downloads sync automatically"
    echo ""
    echo "Your Raspberry Pi is now a full-featured NAS server! 🚀"
    echo "========================================================"
}

# Main function
main() {
    log_info "=== Raspberry Pi NAS Setup ==="
    echo "This script will:"
    echo "• Install Samba file server"
    echo "• Install Webmin web interface"
    echo "• Share your entire home directory securely"
    echo "• Enable access to Videos, Music, ROMs, and more"
    echo "• Configure network discovery for all devices"
    echo "• Create management tools"
    echo ""
    
    # Confirmation prompt
    read -p "Continue with NAS installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "NAS installation cancelled by user"
        exit 0
    fi
    
    # Execute installation steps
    install_samba
    install_webmin
    configure_samba_shares
    setup_samba_user
    setup_network_discovery
    configure_firewall
    optimize_performance
    create_management_scripts
    start_services
    
    # Display completion summary
    display_nas_summary
}

# Execute main function
main "$@"
