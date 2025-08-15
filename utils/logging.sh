# Logging utilities removed - using simple echo statements instead

# Internal logging function
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Format message
    local console_msg="${color}[${level}]${NC} ${message}"
    local file_msg="[$timestamp] [$level] $message"
    
    # Output to console
    if [ "$LOG_TO_CONSOLE" = "true" ]; then
        echo -e "$console_msg"
    fi
    
    # Output to file
    if [ "$LOG_TO_FILE" = "true" ] && [ -n "$LOG_FILE" ]; then
        echo "$file_msg" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Logging functions
log_info() {
    _log "INFO" "$BLUE" "$1"
}

log_success() {
    _log "SUCCESS" "$GREEN" "$1"
}

log_warn() {
    _log "WARN" "$YELLOW" "$1"
}

log_error() {
    _log "ERROR" "$RED" "$1"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        _log "DEBUG" "$PURPLE" "$1"
    fi
}

# Function to log command execution
log_command() {
    local cmd="$1"
    log_debug "Executing: $cmd"
    
    if [ "$LOG_TO_FILE" = "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [COMMAND] $cmd" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Function to log with custom color
log_custom() {
    local color="$1"
    local level="$2"
    local message="$3"
    _log "$level" "$color" "$message"
}

# Function to create a separator line in logs
log_separator() {
    local char="${1:-=}"
    local length="${2:-50}"
    local separator="$(printf "%${length}s" | tr ' ' "$char")"
    
    if [ "$LOG_TO_CONSOLE" = "true" ]; then
        echo -e "${CYAN}$separator${NC}"
    fi
    
    if [ "$LOG_TO_FILE" = "true" ] && [ -n "$LOG_FILE" ]; then
        echo "$separator" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Function to start a section
log_section() {
    local title="$1"
    log_separator "="
    log_custom "$WHITE" "SECTION" "$title"
    log_separator "="
}

# Function to end a section
log_section_end() {
    local title="${1:-Section Complete}"
    log_separator "-"
    log_success "$title"
    log_separator "-"
    echo ""
}

# Function to log script start
log_script_start() {
    local script_name="$1"
    local version="${2:-1.0.0}"
    
    log_separator "="
    log_custom "$CYAN" "START" "Starting $script_name (v$version)"
    log_custom "$CYAN" "START" "Timestamp: $(date)"
    log_custom "$CYAN" "START" "User: $(whoami)"
    log_custom "$CYAN" "START" "PWD: $(pwd)"
    log_separator "="
    echo ""
}

# Function to log script end
log_script_end() {
    local script_name="$1"
    local exit_code="${2:-0}"
    
    echo ""
    log_separator "="
    if [ "$exit_code" -eq 0 ]; then
        log_success "$script_name completed successfully"
    else
        log_error "$script_name failed with exit code $exit_code"
    fi
    log_custom "$CYAN" "END" "Timestamp: $(date)"
    log_separator "="
}

# Function to show progress
show_progress() {
    local current="$1"
    local total="$2"
    local task="$3"
    local percentage=$((current * 100 / total))
    
    printf "\r${BLUE}[%3d%%]${NC} %s" "$percentage" "$task"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}
