#!/bin/bash

###############################################################################
# Common Utilities for RaspiCommandCenter
# 
# Provides common functions used across all scripts
#
# Author: RaspiCommandCenter
# Version: 1.0.0
###############################################################################

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if NOT running as root
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "This script should NOT be run as root"
        log_error "Please run as a regular user"
        exit 1
    fi
}

# Function to check if user exists
user_exists() {
    local username="$1"
    id "$username" >/dev/null 2>&1
}

# Function to check if group exists
group_exists() {
    local groupname="$1"
    getent group "$groupname" >/dev/null 2>&1
}

# Function to check if package is installed (Debian/Ubuntu)
package_installed() {
    local package="$1"
    dpkg -l | grep -q "^ii  $package "
}

# Function to check if service is running
service_running() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Function to check if service is enabled
service_enabled() {
    local service="$1"
    systemctl is-enabled --quiet "$service"
}

# Function to check if port is open
port_open() {
    local port="$1"
    local host="${2:-localhost}"
    timeout 3 bash -c "</dev/tcp/$host/$port" >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local service="$1"
    local timeout="${2:-60}"
    local counter=0
    
    log_info "Waiting for $service to be ready (timeout: ${timeout}s)..."
    
    while [ $counter -lt $timeout ]; do
        if service_running "$service"; then
            log_success "$service is ready"
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
        printf "."
    done
    
    echo ""
    log_error "$service did not start within ${timeout} seconds"
    return 1
}

# Function to wait for port to be open
wait_for_port() {
    local port="$1"
    local host="${2:-localhost}"
    local timeout="${3:-60}"
    local counter=0
    
    log_info "Waiting for port $port on $host to be open (timeout: ${timeout}s)..."
    
    while [ $counter -lt $timeout ]; do
        if port_open "$port" "$host"; then
            log_success "Port $port is open on $host"
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
        printf "."
    done
    
    echo ""
    log_error "Port $port on $host did not open within ${timeout} seconds"
    return 1
}

###############################################################################
# Docker Conflict Prevention Functions
###############################################################################

# Function to check if Docker is running
docker_running() {
    systemctl is-active --quiet docker 2>/dev/null
}

# Function to check if Docker container exists (running or stopped)
docker_container_exists() {
    local container_name="$1"
    [ -n "$container_name" ] && docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$" 2>/dev/null
}

# Function to check if Docker container is running
docker_container_running() {
    local container_name="$1"
    [ -n "$container_name" ] && docker ps --format "table {{.Names}}" | grep -q "^${container_name}$" 2>/dev/null
}

# Function to stop and remove Docker container if it exists
docker_cleanup_container() {
    local container_name="$1"
    
    if [ -z "$container_name" ]; then
        log_error "Container name is required for cleanup"
        return 1
    fi
    
    if docker_container_exists "$container_name"; then
        log_info "Found existing container: $container_name"
        
        if docker_container_running "$container_name"; then
            log_info "Stopping container: $container_name"
            docker stop "$container_name" >/dev/null 2>&1 || log_warning "Failed to stop container: $container_name"
        fi
        
        log_info "Removing container: $container_name"
        docker rm "$container_name" >/dev/null 2>&1 || log_warning "Failed to remove container: $container_name"
        
        log_success "Container $container_name cleaned up"
    else
        log_info "Container $container_name does not exist, nothing to clean up"
    fi
}

# Function to check if port is in use and by what
check_port_usage() {
    local port="$1"
    
    if [ -z "$port" ]; then
        log_error "Port number is required"
        return 1
    fi
    
    # Check if port is in use
    if ss -tulpn | grep -q ":${port} "; then
        log_warning "Port $port is already in use:"
        ss -tulpn | grep ":${port} " | while read line; do
            log_warning "  $line"
        done
        return 0  # Port is in use
    else
        log_info "Port $port is available"
        return 1  # Port is free
    fi
}

# Function to check for Home Assistant container conflicts
check_homeassistant_conflicts() {
    log_info "Checking for Home Assistant conflicts..."
    
    # Check port 8123
    if check_port_usage 8123; then
        log_warning "Home Assistant port 8123 is in use"
        echo "Do you want to stop any existing Home Assistant services? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Stop common Home Assistant containers
            for container in homeassistant hassio_supervisor hassio_dns hassio_audio hassio_multicast; do
                docker_cleanup_container "$container"
            done
            
            # Kill any process using port 8123
            local pid=$(ss -tulpn | grep ":8123 " | grep -o 'pid=[0-9]*' | cut -d= -f2 | head -1)
            if [ -n "$pid" ]; then
                log_info "Stopping process $pid using port 8123"
                kill "$pid" 2>/dev/null || log_warning "Failed to stop process $pid"
            fi
        else
            log_error "Cannot proceed with Home Assistant installation while port 8123 is in use"
            return 1
        fi
    fi
    
    return 0
}

# Function to check for general Docker conflicts before starting services
check_docker_conflicts() {
    local service_name="$1"
    local port="$2"
    local container_name="$3"
    
    log_info "Checking Docker conflicts for $service_name..."
    
    # Ensure Docker is running
    if ! docker_running; then
        log_info "Starting Docker service..."
        systemctl start docker
        sleep 3
        
        if ! docker_running; then
            log_error "Failed to start Docker service"
            return 1
        fi
    fi
    
    # Check for port conflicts
    if [ -n "$port" ] && check_port_usage "$port"; then
        log_warning "Port $port is in use, which may conflict with $service_name"
    fi
    
    # Check for container name conflicts
    if [ -n "$container_name" ] && docker_container_exists "$container_name"; then
        log_warning "Container $container_name already exists"
        echo "Do you want to remove the existing container? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            docker_cleanup_container "$container_name"
        else
            log_error "Cannot proceed while container $container_name exists"
            return 1
        fi
    fi
    
    return 0
}

# Function to get system information
get_system_info() {
    echo "=== System Information ==="
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h | grep Mem: | awk '{print $3 "/" $2}')"
    echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
    
    if [ -f /proc/cpuinfo ]; then
        echo "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[ \t]*//')"
        echo "CPU Cores: $(nproc)"
    fi
    
    if command -v vcgencmd >/dev/null 2>&1; then
        echo "Temperature: $(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 || echo 'N/A')"
    fi
}

# Function to check available disk space
check_disk_space() {
    local path="${1:-/}"
    local required_gb="${2:-5}"
    
    local available_kb=$(df "$path" | tail -1 | awk '{print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        log_error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        return 1
    else
        log_info "Disk space check passed. Available: ${available_gb}GB"
        return 0
    fi
}

# Function to check memory requirements
check_memory() {
    local required_mb="${1:-1024}"
    
    local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_mb=$((total_mem_kb / 1024))
    
    if [ "$total_mem_mb" -lt "$required_mb" ]; then
        log_error "Insufficient memory. Required: ${required_mb}MB, Available: ${total_mem_mb}MB"
        return 1
    else
        log_info "Memory check passed. Available: ${total_mem_mb}MB"
        return 0
    fi
}

# Function to backup a file
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [ -f "$file" ]; then
        local backup_file="${file}${backup_suffix}"
        cp "$file" "$backup_file"
        log_info "Backed up $file to $backup_file"
        echo "$backup_file"
    else
        log_warn "File $file does not exist, cannot backup"
        return 1
    fi
}

# Function to restore a file from backup
restore_file() {
    local backup_file="$1"
    local original_file="${backup_file%%.backup.*}"
    
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$original_file"
        log_info "Restored $original_file from $backup_file"
    else
        log_error "Backup file $backup_file does not exist"
        return 1
    fi
}

# Function to retry a command
retry_command() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local command="$@"
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log_info "Attempt $attempt/$max_attempts: $command"
        
        if eval "$command"; then
            log_success "Command succeeded on attempt $attempt"
            return 0
        else
            log_warn "Command failed on attempt $attempt"
            if [ $attempt -lt $max_attempts ]; then
                log_info "Waiting ${delay} seconds before retry..."
                sleep "$delay"
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Command failed after $max_attempts attempts"
    return 1
}

# Function to validate IP address
validate_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ $ip =~ $regex ]]; then
        # Check each octet is 0-255
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [ "$i" -gt 255 ]; then
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

# Function to get default network interface
get_default_interface() {
    ip route | grep default | head -1 | awk '{print $5}'
}

# Function to get IP address of interface
get_interface_ip() {
    local interface="${1:-$(get_default_interface)}"
    ip addr show "$interface" | grep 'inet ' | head -1 | awk '{print $2}' | cut -d'/' -f1
}

# Function to check internet connectivity
check_internet() {
    local test_urls=("8.8.8.8" "1.1.1.1" "google.com")
    
    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 5 "$url" >/dev/null 2>&1; then
            log_info "Internet connectivity confirmed (via $url)"
            return 0
        fi
    done
    
    log_error "No internet connectivity detected"
    return 1
}

# Function to download file with retry
download_file() {
    local url="$1"
    local output="$2"
    local max_attempts="${3:-3}"
    
    for attempt in $(seq 1 $max_attempts); do
        log_info "Downloading $url (attempt $attempt/$max_attempts)..."
        
        if command -v wget >/dev/null 2>&1; then
            if wget -O "$output" "$url" 2>/dev/null; then
                log_success "Download completed: $output"
                return 0
            fi
        elif command -v curl >/dev/null 2>&1; then
            if curl -L -o "$output" "$url" 2>/dev/null; then
                log_success "Download completed: $output"
                return 0
            fi
        else
            log_error "Neither wget nor curl is available"
            return 1
        fi
        
        log_warn "Download attempt $attempt failed"
        if [ $attempt -lt $max_attempts ]; then
            sleep 2
        fi
    done
    
    log_error "Failed to download $url after $max_attempts attempts"
    return 1
}

# Function to create systemd service
create_systemd_service() {
    local service_name="$1"
    local service_content="$2"
    local service_file="/etc/systemd/system/${service_name}.service"
    
    echo "$service_content" | sudo tee "$service_file" > /dev/null
    sudo systemctl daemon-reload
    
    log_info "Created systemd service: $service_name"
}

# Function to enable and start service
enable_start_service() {
    local service_name="$1"
    
    sudo systemctl enable "$service_name"
    sudo systemctl start "$service_name"
    
    if service_running "$service_name"; then
        log_success "Service $service_name enabled and started"
    else
        log_error "Failed to start service $service_name"
        return 1
    fi
}

# Function to prompt for user input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local response
    
    read -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

# Function to prompt for yes/no with default
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        read -p "$prompt (y/n) [$default]: " response
        response="${response:-$default}"
        
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}
