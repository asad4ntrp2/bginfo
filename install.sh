#!/usr/bin/env bash
#
# BGInfo for Linux - Universal System Monitor Installer
# https://github.com/asad4ntrp2/bginfo
#
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash
#
# Version: 1.0.0
# License: MIT

set -euo pipefail

VERSION="1.0.0"
REPO="https://github.com/asad4ntrp2/bginfo"
CONFIG_DIR="$HOME/.config/conky"
CONFIG_FILE="$CONFIG_DIR/conky.conf"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/bginfo-conky.desktop"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║       BGInfo for Linux v${VERSION}           ║"
    echo "║   Live System Monitor on Your Desktop    ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${BLUE}[STEP]${NC} $1"; }

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_NAME="${PRETTY_NAME:-Unknown Linux}"
        DISTRO_VERSION="${VERSION_ID:-}"
    elif [ -f /etc/redhat-release ]; then
        DISTRO_ID="rhel"
        DISTRO_NAME=$(cat /etc/redhat-release)
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
    fi
    log_info "Detected: $DISTRO_NAME"
}

# Detect package manager
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MGR="apt"
        PKG_INSTALL="sudo apt-get install -y"
        PKG_UPDATE="sudo apt-get update -qq"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
    elif command -v yum &>/dev/null; then
        PKG_MGR="yum"
        PKG_INSTALL="sudo yum install -y"
        PKG_UPDATE="sudo yum check-update || true"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
    elif command -v zypper &>/dev/null; then
        PKG_MGR="zypper"
        PKG_INSTALL="sudo zypper install -y"
        PKG_UPDATE="sudo zypper refresh"
    else
        log_error "No supported package manager found!"
        exit 1
    fi
    log_info "Package manager: $PKG_MGR"
}

# Install Conky and dependencies
install_packages() {
    log_step "Installing Conky and dependencies..."
    $PKG_UPDATE 2>/dev/null

    case "$PKG_MGR" in
        apt)
            $PKG_INSTALL conky-all fonts-jetbrains-mono lm-sensors 2>/dev/null || \
            $PKG_INSTALL conky fonts-jetbrains-mono lm-sensors 2>/dev/null
            ;;
        dnf|yum)
            $PKG_INSTALL conky jetbrains-mono-fonts-all lm_sensors 2>/dev/null || \
            $PKG_INSTALL conky lm_sensors 2>/dev/null
            ;;
        pacman)
            $PKG_INSTALL conky ttf-jetbrains-mono lm_sensors 2>/dev/null || \
            $PKG_INSTALL conky lm_sensors 2>/dev/null
            ;;
        zypper)
            $PKG_INSTALL conky jetbrains-mono-fonts lm_sensors 2>/dev/null || \
            $PKG_INSTALL conky lm_sensors 2>/dev/null
            ;;
    esac

    if ! command -v conky &>/dev/null; then
        log_error "Failed to install Conky. Please install it manually."
        exit 1
    fi
    log_info "Conky installed successfully"
}

# Detect system hardware
detect_hardware() {
    log_step "Detecting hardware..."

    # CPU
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //' | sed 's/(R)//g;s/(TM)//g;s/CPU //g' | cut -c1-30)
    CPU_CORES=$(nproc 2>/dev/null || echo 4)

    # RAM
    RAM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')

    # Network interface (first non-loopback)
    NET_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v lo | head -1)
    if [ -z "$NET_IFACE" ]; then
        NET_IFACE=$(ls /sys/class/net/ 2>/dev/null | grep -v lo | head -1)
    fi
    [ -z "$NET_IFACE" ] && NET_IFACE="eth0"

    # Disk device
    DISK_DEV=$(df / 2>/dev/null | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' | sed 's/p$//')
    [ -z "$DISK_DEV" ] && DISK_DEV="/dev/sda"

    # Hostname
    SYS_HOSTNAME=$(hostname 2>/dev/null | tr '[:lower:]' '[:upper:]')

    # Detect if VM
    IS_VM="no"
    if command -v systemd-detect-virt &>/dev/null; then
        VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")
        [ "$VIRT_TYPE" != "none" ] && IS_VM="yes"
    fi

    log_info "CPU: $CPU_MODEL ($CPU_CORES cores)"
    log_info "RAM: $RAM_TOTAL"
    log_info "Network: $NET_IFACE"
    log_info "Disk: $DISK_DEV"
    log_info "Hostname: $SYS_HOSTNAME"
}

# Generate CPU core lines based on core count
generate_cpu_cores() {
    local cores=$1
    local output=""
    local i=1
    while [ $i -le "$cores" ]; do
        local col=$(( (i - 1) % 3 ))
        local padded_i=$(printf "%2d" $i)
        if [ $col -eq 0 ]; then
            output+="\${color2}\${font JetBrains Mono:size=8}\${goto 10}"
        fi
        case $col in
            0) output+="Core${padded_i}: \${color}\${cpu cpu${i}}%" ;;
            1) output+="\${goto 110}\${color2}Core${padded_i}: \${color}\${cpu cpu${i}}%" ;;
            2) output+="\${goto 210}\${color2}Core${padded_i}: \${color}\${cpu cpu${i}}%" ;;
        esac
        if [ $col -eq 2 ] || [ $i -eq "$cores" ]; then
            output+="\n"
        fi
        i=$((i + 1))
    done
    # Close font tag
    output+="\${font}"
    echo -e "$output"
}

# Generate Conky config
generate_config() {
    log_step "Generating configuration..."

    mkdir -p "$CONFIG_DIR"

    # Check if JetBrains Mono is available, fallback to monospace
    if fc-list 2>/dev/null | grep -qi "jetbrains"; then
        FONT="JetBrains Mono"
    elif fc-list 2>/dev/null | grep -qi "DejaVu Sans Mono"; then
        FONT="DejaVu Sans Mono"
    else
        FONT="monospace"
    fi

    CPU_CORES_BLOCK=$(generate_cpu_cores "$CPU_CORES")

    cat > "$CONFIG_FILE" << CONKYEOF
-- BGInfo for Linux v${VERSION}
-- Auto-generated on $(date '+%Y-%m-%d %H:%M:%S')
-- ${REPO}

conky.config = {
    -- Window
    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_transparent = false,
    own_window_argb_visual = true,
    own_window_argb_value = 200,
    own_window_colour = '0d1117',
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    -- Position & Size
    alignment = 'top_right',
    gap_x = 20,
    gap_y = 40,
    minimum_width = 320,
    maximum_width = 320,
    minimum_height = 5,

    -- Borders & Margins
    border_width = 0,
    border_inner_margin = 15,
    border_outer_margin = 0,
    draw_borders = false,
    draw_outline = false,
    draw_shades = false,
    draw_graph_borders = false,

    -- Fonts & Colors
    use_xft = true,
    font = '${FONT}:size=9',
    override_utf8_locale = true,
    default_color = 'c9d1d9',
    default_outline_color = '21262d',
    color1 = '58a6ff',    -- Accent blue
    color2 = '8b949e',    -- Muted gray
    color3 = '3fb950',    -- Green
    color4 = 'f0883e',    -- Orange/warning
    color5 = 'f85149',    -- Red/critical
    color6 = 'd2a8ff',    -- Purple

    -- Performance
    update_interval = 2.0,
    cpu_avg_samples = 4,
    net_avg_samples = 2,
    double_buffer = true,
    no_buffers = true,
    text_buffer_size = 2048,

    -- Misc
    background = false,
    use_spacer = 'none',
    short_units = true,
    pad_percents = 2,
    top_name_width = 15,
};

conky.text = [[
\${color1}\${font ${FONT}:bold:size=14}${SYS_HOSTNAME}\${font}\${color2}  \${hr 1}
\${color2}\${font ${FONT}:size=8}\${execi 3600 lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY | cut -d'"' -f2}  |  Kernel: \${kernel}\${font}
\${color2}Uptime:\${color} \${uptime_short}\${alignr}\${color2}Load:\${color} \${loadavg 1} \${loadavg 2} \${loadavg 3}

\${color1}CPU \${color2}\${hr 1}
\${color2}${CPU_MODEL}\${alignr}\${color}\${freq_g}GHz  \${cpu cpu0}%
\${color3}\${cpubar cpu0 6}
${CPU_CORES_BLOCK}

\${color1}MEMORY \${color2}\${hr 1}
\${color2}RAM:\${color}  \${mem} / \${memmax}\${alignr}\${memperc}%
\${color3}\${membar 6}
\${color2}Swap:\${color} \${swap} / \${swapmax}\${alignr}\${swapperc}%
\${color3}\${swapbar 6}
\${color2}Buffers:\${color} \${buffers}\${alignr}\${color2}Cached:\${color} \${cached}

\${color1}DISK \${color2}\${hr 1}
\${color2}/\${alignr}\${color}\${fs_used /} / \${fs_size /}  (\${fs_used_perc /}%)
\${color3}\${fs_bar 6 /}
\${color2}Read: \${color}\${diskio_read ${DISK_DEV}}\${alignr}\${color2}Write: \${color}\${diskio_write ${DISK_DEV}}

\${color1}NETWORK \${color2}\${hr 1}
\${color2}Interface:\${color} ${NET_IFACE}\${alignr}\${color2}IP:\${color} \${addr ${NET_IFACE}}
\${color2}Down:\${color} \${downspeed ${NET_IFACE}}\${alignr}\${color2}Up:\${color} \${upspeed ${NET_IFACE}}
\${color3}\${downspeedgraph ${NET_IFACE} 30,148 3fb950 58a6ff -t} \${color4}\${upspeedgraph ${NET_IFACE} 30,148 f0883e f85149 -t}
\${color2}Total Down:\${color} \${totaldown ${NET_IFACE}}\${alignr}\${color2}Total Up:\${color} \${totalup ${NET_IFACE}}

\${color1}TOP PROCESSES \${color2}\${hr 1}
\${color2}Name\${goto 140}PID\${goto 195}CPU%\${goto 260}MEM%
\${color}\${top name 1}\${goto 130}\${top pid 1}\${goto 190}\${top cpu 1}%\${goto 255}\${top mem 1}%
\${color}\${top name 2}\${goto 130}\${top pid 2}\${goto 190}\${top cpu 2}%\${goto 255}\${top mem 2}%
\${color}\${top name 3}\${goto 130}\${top pid 3}\${goto 190}\${top cpu 3}%\${goto 255}\${top mem 3}%
\${color}\${top name 4}\${goto 130}\${top pid 4}\${goto 190}\${top cpu 4}%\${goto 255}\${top mem 4}%
\${color}\${top name 5}\${goto 130}\${top pid 5}\${goto 190}\${top cpu 5}%\${goto 255}\${top mem 5}%

\${color1}TOP MEMORY \${color2}\${hr 1}
\${color2}Name\${goto 140}PID\${goto 195}CPU%\${goto 260}MEM%
\${color}\${top_mem name 1}\${goto 130}\${top_mem pid 1}\${goto 190}\${top_mem cpu 1}%\${goto 255}\${top_mem mem 1}%
\${color}\${top_mem name 2}\${goto 130}\${top_mem pid 2}\${goto 190}\${top_mem cpu 2}%\${goto 255}\${top_mem mem 2}%
\${color}\${top_mem name 3}\${goto 130}\${top_mem pid 3}\${goto 190}\${top_mem cpu 3}%\${goto 255}\${top_mem mem 3}%

\${color1}SERVICES \${color2}\${hr 1}
\${color2}SSH:\${alignr}\${if_running sshd}\${color3}RUNNING\${else}\${color5}STOPPED\${endif}
\${color2}Docker:\${alignr}\${if_running dockerd}\${color3}RUNNING\${else}\${color5}STOPPED\${endif}
\${color2}Firewall:\${alignr}\${if_running ufw}\${color3}ACTIVE\${else}\${color5}INACTIVE\${endif}

\${color2}\${font ${FONT}:size=7}\${alignc}BGInfo v${VERSION}  |  ${SYS_HOSTNAME}  |  \${time %A %d %B %Y  %H:%M:%S}\${font}
]];
CONKYEOF

    log_info "Configuration saved to $CONFIG_FILE"
}

# Setup autostart
setup_autostart() {
    log_step "Setting up autostart..."
    mkdir -p "$AUTOSTART_DIR"

    cat > "$AUTOSTART_FILE" << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=BGInfo System Monitor
Exec=/usr/bin/conky --daemonize --pause=5
StartupNotify=false
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
Comment=BGInfo - Live system resource monitor on desktop
DESKTOP_EOF

    log_info "Autostart configured"
}

# Handle Wayland (disable for Conky compatibility)
handle_wayland() {
    if [ -f /etc/gdm3/custom.conf ]; then
        if grep -q "#WaylandEnable=false" /etc/gdm3/custom.conf 2>/dev/null; then
            log_step "Switching GDM to X11 for Conky compatibility..."
            sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
            log_warn "Wayland disabled. Please log out and back in for Conky to display."
        fi
    elif [ -f /etc/gdm/custom.conf ]; then
        if grep -q "#WaylandEnable=false" /etc/gdm/custom.conf 2>/dev/null; then
            sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm/custom.conf
            log_warn "Wayland disabled. Please log out and back in for Conky to display."
        fi
    fi
}

# Start Conky
start_conky() {
    log_step "Starting BGInfo..."
    killall conky 2>/dev/null || true
    sleep 1

    if [ -n "${DISPLAY:-}" ]; then
        conky --daemonize --pause=3 2>/dev/null && \
            log_info "BGInfo is running on your desktop!" || \
            log_warn "Could not start Conky. It will start on next login."
    else
        log_warn "No display detected (SSH session?). BGInfo will start on next login."
    fi
}

# Uninstall
uninstall() {
    echo -e "${YELLOW}Uninstalling BGInfo...${NC}"
    killall conky 2>/dev/null || true
    rm -f "$CONFIG_FILE" 2>/dev/null
    rm -f "$AUTOSTART_FILE" 2>/dev/null
    rmdir "$CONFIG_DIR" 2>/dev/null || true
    log_info "BGInfo removed. Conky package was left installed."
    echo -e "${GREEN}BGInfo uninstalled successfully!${NC}"
    exit 0
}

# Print summary
print_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        BGInfo Installation Complete      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}System:${NC}     $DISTRO_NAME"
    echo -e "  ${GREEN}Hostname:${NC}   $SYS_HOSTNAME"
    echo -e "  ${GREEN}CPU:${NC}        $CPU_MODEL ($CPU_CORES cores)"
    echo -e "  ${GREEN}RAM:${NC}        $RAM_TOTAL"
    echo -e "  ${GREEN}Network:${NC}    $NET_IFACE"
    echo -e "  ${GREEN}Config:${NC}     $CONFIG_FILE"
    echo -e "  ${GREEN}Autostart:${NC}  $AUTOSTART_FILE"
    echo -e "  ${GREEN}Version:${NC}    $VERSION"
    echo ""
    echo -e "  ${YELLOW}If Conky is not visible, log out and back in.${NC}"
    echo -e "  ${YELLOW}To uninstall: curl -fsSL $REPO/raw/main/install.sh | bash -s -- --uninstall${NC}"
    echo ""
}

# Main
main() {
    # Handle flags
    case "${1:-}" in
        --uninstall|-u) uninstall ;;
        --version|-v) echo "BGInfo for Linux v${VERSION}"; exit 0 ;;
        --help|-h)
            echo "BGInfo for Linux v${VERSION}"
            echo ""
            echo "Usage: install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --uninstall, -u    Remove BGInfo"
            echo "  --version, -v      Show version"
            echo "  --help, -h         Show this help"
            exit 0
            ;;
    esac

    print_banner
    detect_distro
    detect_pkg_manager
    install_packages
    detect_hardware
    generate_config
    setup_autostart
    handle_wayland
    start_conky
    print_summary
}

main "$@"
