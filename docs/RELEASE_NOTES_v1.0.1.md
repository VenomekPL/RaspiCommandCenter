# RaspiCommandCenter v1.0.1 Release Notes

**Release Date:** August 14, 2025  
**Type:** Bug Fix Release  
**Target Platform:** Raspberry Pi 5 with NVME SSD  

## 🐛 Bug Fixes

### **Critical Fix: Readonly Variable Conflicts**
- **Fixed** `logging.sh` line 23 readonly variable error that prevented installation
- **Resolved** LOG_FILE assignment conflicts between scripts
- **Improved** script sourcing order in `setup_homeassistant.sh`

### **Technical Details**
- **Problem**: Multiple scripts declaring `readonly LOG_FILE` caused conflicts with logging.sh defaults
- **Solution**: Made logging.sh defensive by checking if LOG_FILE is already defined before setting default
- **Impact**: Fixes installation failures during Phase 1 and Phase 2 setup

## 🔧 Changes Made

### **utils/logging.sh**
- Modified LOG_FILE initialization to respect existing readonly declarations
- Improved setup_logging() function to use local variables consistently
- Better error handling for readonly variable scenarios

### **scripts/setup_homeassistant.sh**
- Fixed sourcing order: declare LOG_FILE before sourcing logging.sh
- Prevents readonly variable conflicts during Home Assistant setup

### **Version Updates**
- Updated version number from 2.0.0 to 1.0.1 (corrected versioning)
- Maintained all existing functionality and features

## ✅ Validation

### **Tested Scenarios**
- [x] start.sh Phase 1 execution without readonly errors
- [x] setup_homeassistant.sh execution without conflicts
- [x] All other scripts maintain proper LOG_FILE handling
- [x] Backward compatibility with existing installations

### **No Breaking Changes**
- All existing features and functionality preserved
- Installation process remains identical for users
- No configuration changes required

## 🚀 Installation

**For New Installations:**
```bash
git clone https://github.com/VenomekPL/RaspiCommandCenter.git
cd RaspiCommandCenter
chmod +x *.sh scripts/*.sh
./start.sh
```

**For Existing v1.0.0 Users:**
```bash
cd RaspiCommandCenter
git pull origin main
./start.sh
```

## 📈 What's Next

This bug fix release ensures reliable installation across different Raspberry Pi configurations. The next release will focus on:

- Enhanced error reporting and diagnostics
- Additional emulator cores and systems
- Performance monitoring dashboard
- Backup and restore utilities

## 🎯 Impact

v1.0.1 resolves the primary installation blocker reported during initial testing, ensuring that RaspiCommandCenter can be successfully deployed on fresh Raspberry Pi 5 systems without script execution errors.

**This release is recommended for all users attempting fresh installations.**

---

**Previous Release**: [v1.0.0](RELEASE_NOTES_v1.0.0.md) - Initial release  
**Repository**: https://github.com/VenomekPL/RaspiCommandCenter  
**Issues**: https://github.com/VenomekPL/RaspiCommandCenter/issues
