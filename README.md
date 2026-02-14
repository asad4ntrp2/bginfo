# BGInfo for Linux

A universal, one-command system information display for Linux desktops. Similar to Microsoft's BGInfo for Windows, this tool shows live system stats directly on your desktop background.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash
```

That's it. One command installs everything, auto-detects your hardware, and starts the monitor.

## What It Shows

| Section | Information |
|---------|------------|
| **System** | Hostname, OS, Kernel, Uptime, Load Average |
| **CPU** | Model, Frequency, Per-core usage with bars |
| **Memory** | RAM/Swap usage with bars, Buffers, Cache |
| **Disk** | Root partition usage, Read/Write speeds |
| **Network** | Interface, IP, Download/Upload speeds with graphs |
| **Processes** | Top 5 by CPU, Top 3 by Memory |
| **Services** | SSH, Docker, Firewall status |

## Features

- **One-command install** - Works on any major Linux distro
- **Auto-detection** - Detects CPU cores, network interface, disk, hostname
- **Dark theme** - Sleek GitHub-inspired dark transparent overlay
- **Auto-start** - Launches on every login
- **Lightweight** - ~10MB RAM, minimal CPU usage
- **Per-core monitoring** - Adapts to your CPU core count (2 to 64+)
- **Live graphs** - Network upload/download speed graphs
- **Wayland handling** - Auto-switches to X11 for compatibility

## Supported Distributions

| Distro | Package Manager | Status |
|--------|----------------|--------|
| Ubuntu / Kubuntu / Xubuntu | apt | Tested |
| Debian | apt | Tested |
| Linux Mint | apt | Tested |
| Fedora | dnf | Supported |
| CentOS / RHEL / Rocky / Alma | dnf/yum | Supported |
| Arch Linux / Manjaro | pacman | Supported |
| openSUSE | zypper | Supported |

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash -s -- --uninstall
```

Or manually:

```bash
killall conky
rm -f ~/.config/conky/conky.conf
rm -f ~/.config/autostart/bginfo-conky.desktop
```

## Configuration

The config file is at `~/.config/conky/conky.conf`. You can customize:

- **Position**: Change `alignment` (top_right, top_left, bottom_right, bottom_left, middle_middle)
- **Colors**: Modify color1-color6 values (hex colors)
- **Update interval**: Change `update_interval` (in seconds)
- **Transparency**: Adjust `own_window_argb_value` (0-255, where 0 = fully transparent)
- **Size**: Modify `minimum_width` and `maximum_width`

## Command Line Options

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash

# Uninstall
curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash -s -- --uninstall

# Show version
curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash -s -- --version

# Show help
curl -fsSL https://raw.githubusercontent.com/asad4ntrp2/bginfo/main/install.sh | bash -s -- --help
```

## Requirements

- Linux with a desktop environment (GNOME, KDE, XFCE, etc.)
- `sudo` access (for installing packages)
- Internet connection (for downloading packages)

## How It Works

1. Detects your Linux distribution and package manager
2. Installs Conky (lightweight system monitor) and fonts
3. Detects your hardware (CPU, RAM, network, disk)
4. Generates a customized config based on your system
5. Sets up autostart so it runs on every login
6. Handles Wayland/X11 compatibility

## Troubleshooting

**Conky not visible after install?**
- Log out and log back in (required if Wayland was disabled)
- Or reboot your machine

**Want to restart Conky manually?**
```bash
killall conky; conky --daemonize --pause=3
```

**Wrong network interface?**
- Edit `~/.config/conky/conky.conf` and replace the interface name

## License

MIT License - Free to use, modify, and distribute.

## Credits

Built with [Conky](https://github.com/brndnmtthws/conky) - the lightweight system monitor for X/Wayland.
