#!/bin/bash

set -e

### CONFIG ###
USER_NAME=$(whoami)
HOME_DIR="/home/$USER_NAME"

# Ensure we're not root
if [ "$EUID" -eq 0 ]; then
  echo "Please run as a regular user with sudo privileges, not as root."
  exit 1
fi

# Update system
sudo pacman -Syu --noconfirm

# Install core utilities
sudo pacman -S --noconfirm git base-devel sudo networkmanager

# Enable NetworkManager
sudo systemctl enable --now NetworkManager

# Install LTS kernel utilities (already installed if user chose linux-lts)
sudo pacman -S --noconfirm linux-lts linux-lts-headers

# Install power + thermal management tools
sudo pacman -S --noconfirm tlp thermald auto-cpufreq acpi acpid
sudo systemctl enable --now tlp thermald auto-cpufreqd acpid

# Install Hyprland and dependencies
sudo pacman -S --noconfirm hyprland kitty waybar rofi swww brightnessctl \
  pipewire wireplumber pavucontrol network-manager-applet bluez bluez-utils \
  polkit-gnome gvfs udiskie wl-clipboard grim slurp unzip noto-fonts ttf-nerd-fonts-symbols \
  ttf-jetbrains-mono ttf-dejavu ttf-font-awesome

# Enable Bluetooth
sudo systemctl enable --now bluetooth

# Clone HyDE Project
mkdir -p "$HOME_DIR/.config"
git clone https://github.com/hyprland-community/Hyprland-HyDE.git /tmp/HyDE

# Backup existing config
[ -d "$HOME_DIR/.config/hypr" ] && mv "$HOME_DIR/.config/hypr" "$HOME_DIR/.config/hypr.bak"

# Copy HyDE config
cp -r /tmp/HyDE/hypr "$HOME_DIR/.config/hypr"

# Set kitty as default terminal in Hyprland config
sed -i 's/foot/kitty/g' "$HOME_DIR/.config/hypr/hyprland.conf"

# Set proper ownership
chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR/.config"

# Set recommended kernel parameters (append to GRUB)
KERNEL_PARAMS="acpi_osi=Linux acpi_backlight=vendor i915.enable_psr=0"
sudo sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"$KERNEL_PARAMS /" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Final message
echo -e "\n✅ Setup complete. Reboot your system to enjoy Hyprland with HyDE on LTS kernel."
echo -e "\nIf anything breaks, log into TTY (Ctrl+Alt+F2) and rename ~/.config/hypr to reset."

