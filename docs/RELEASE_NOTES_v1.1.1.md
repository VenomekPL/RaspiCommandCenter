# RaspiCommandCenter v1.1.1 Release Notes

**Release Date:** August 15, 2025  
**Type:** Patch Release - Bug Fix  
**Target Platform:** Raspberry Pi 5 with NVME SSD  

## 🐛 Bug Fixes

### **Critical Fix: dbus Command Not Found**
- **Fixed** "dbus command not found" error during Home Assistant setup
- **Resolved** Home Assistant OS Agent installation failures
- **Improved** dbus service configuration and verification

### **Technical Details**
- **Problem**: Package `dbus` doesn't provide the required dbus command-line tools
- **Solution**: Changed to `dbus-user-session` which includes proper dbus utilities
- **Enhancement**: Added `systemd-container` dependency for containerized workloads
- **Verification**: Added dbus service startup and health checks

## 🔧 Changes Made

### **Package Dependencies Updated**
```bash
# OLD (incorrect package)
"dbus"

# NEW (correct packages)
"dbus-user-session"
"systemd-container"
```

### **Service Configuration Added**
```bash
# Ensure dbus service is running
systemctl enable dbus
systemctl start dbus

# Verify dbus is working
systemctl is-active --quiet dbus
```

### **Files Modified**
- **`scripts/install_dependencies.sh`**: Updated dbus package name and added service configuration
- **`scripts/setup_homeassistant.sh`**: Fixed dependencies and added dbus verification

## 🎯 Impact

### **Resolves Issues**
- ✅ Home Assistant OS Agent installation now works correctly
- ✅ `gdbus` commands execute without errors
- ✅ Containerized Home Assistant services start properly
- ✅ No more "command not found" errors during setup

### **Improves Reliability**
- **Service Verification**: Checks dbus is running before proceeding
- **Error Handling**: Better error messages if dbus fails to start
- **Dependencies**: Correct packages for containerized workloads

## 📋 Testing Status

### **Verified On**
- Raspberry Pi 5 with fresh Raspberry Pi OS installation
- Home Assistant Supervised installation process
- dbus service functionality and OS Agent communication

### **Migration from v1.1.0**
- **Automatic**: Simply run `sudo ./start.sh` again
- **Manual**: Install missing packages with:
  ```bash
  sudo apt update
  sudo apt install -y dbus-user-session systemd-container
  sudo systemctl enable dbus
  sudo systemctl start dbus
  ```

## 🚀 Installation

### **Fresh Installation**
```bash
cd ~
git clone https://github.com/VenomekPL/RaspiCommandCenter.git
cd RaspiCommandCenter
chmod +x *.sh scripts/*.sh
sudo ./start.sh
```

### **Update Existing Installation**
```bash
cd ~/RaspiCommandCenter
git pull origin main
sudo ./start.sh
```

## 📊 Version History

- **v1.1.1** - 🐛 Fixed dbus dependency issue
- **v1.1.0** - 🎉 Full automation and safety fixes
- **v1.0.1** - 🔧 Logging conflicts resolved
- **v1.0.0** - 🚀 Initial release

## ⚠️ Important Notes

### **No Breaking Changes**
- All v1.1.0 configurations remain compatible
- Existing installations can be updated safely
- No user intervention required during update

### **Service Dependencies**
- **dbus** is now properly configured for all containerized services
- **Home Assistant Supervised** will install without errors
- **OS Agent** communication works correctly

## 🎉 Summary

Version 1.1.1 is a focused patch release that resolves the critical dbus dependency issue preventing successful Home Assistant installations. This fix ensures the automated setup process works seamlessly from start to finish.

**Key Benefits:**
- ✅ **Fixed Home Assistant setup** - No more dbus errors
- ✅ **Proper service dependencies** - Correct packages installed
- ✅ **Improved reliability** - Service verification added
- ✅ **Zero configuration** - Everything works automatically

**Ready for deployment!** 🚀
