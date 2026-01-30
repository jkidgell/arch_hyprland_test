#!/usr/bin/env bash
set -e

echo "=== Arch Hyprland Post-Install Script ==="

# -------------------------
# Sanity checks
# -------------------------
if ! command -v sudo &>/dev/null; then
  echo "ERROR: sudo is not installed or not configured."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  echo "ERROR: Do not run this script as root."
  exit 1
fi

echo "OK: sudo available, running as user $(whoami)"

# -------------------------
# Enable multilib (required for Steam / lib32)
# -------------------------
echo "Enabling multilib repo (if not already enabled)..."
sudo sed -i '/^\#\[multilib\]$/,/^\#Include/ s/^#//' /etc/pacman.conf
sudo pacman -Sy --needed

# -------------------------
# STAGE 1 – Graphics, audio, portals
# -------------------------
echo "Installing core graphics + audio stack..."

sudo pacman -S --needed \
  linux-firmware \
  mesa lib32-mesa mesa-utils \
  vulkan-radeon lib32-vulkan-radeon vulkan-tools \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal-hyprland \
  polkit-gnome \
  xdg-user-dirs

xdg-user-dirs-update

# -------------------------
# STAGE 2 – Hyprland environment
# -------------------------
echo "Installing Hyprland environment..."

sudo pacman -S --needed \
  hyprland waybar \
  grim slurp wl-clipboard swaybg \
  hypridle hyprlock \
  kitty zsh starship \
  ttf-jetbrains-mono-nerd ttf-firacode-nerd \
  noto-fonts noto-fonts-emoji \
  rofi-wayland \
  thunar thunar-archive-plugin thunar-volman \
  gvfs gvfs-mtp gvfs-smb \
  network-manager-applet \
  qt5-wayland qt6-wayland

# Change shell to zsh (takes effect on next login)
if [[ "$SHELL" != "/bin/zsh" ]]; then
  echo "Changing default shell to zsh..."
  chsh -s /bin/zsh
fi

# -------------------------
# STAGE 3 – System monitors
# -------------------------
echo "Installing system monitors..."

sudo pacman -S --needed \
  btop fastfetch

# -------------------------
# STAGE 4 – greetd + tuigreet
# -------------------------
echo "Installing greetd..."

sudo pacman -S --needed \
  greetd greetd-tuigreet

sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --cmd Hyprland"
user = "greeter"
EOF

sudo systemctl enable greetd

# -------------------------
# STAGE 5 – Gaming stack
# -------------------------
echo "Installing gaming stack..."

sudo pacman -S --needed \
  steam \
  gamemode lib32-gamemode \
  mangohud lib32-mangohud \
  lib32-libpulse lib32-alsa-plugins

systemctl --user enable gamemoded.service || true

# -------------------------
# STAGE 6 – Neovim + CLI helpers
# -------------------------
echo "Installing Neovim..."

sudo pacman -S --needed \
  neovim ripgrep fd

# -------------------------
# Optional but sensible defaults
# -------------------------
echo "Installing optional quality-of-life packages..."

sudo pacman -S --needed \
  bluez bluez-utils \
  ufw

sudo systemctl enable bluetooth
sudo systemctl enable ufw

# -------------------------
# Done
# -------------------------
echo "=== Post-install complete ==="
echo "Reboot recommended."
echo "After reboot: log in via greetd → Hyprland"
