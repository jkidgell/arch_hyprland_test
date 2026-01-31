#!/usr/bin/env bash
set -e

echo "=== Arch Hyprland + Zsh/Kitty/Starship: The Out-of-Box Experience ==="

# -------------------------
# Sanity checks
# -------------------------
if [[ $EUID -eq 0 ]]; then
  echo "ERROR: Do not run this script as root."
  exit 1
fi

# -------------------------
# Enable multilib
# -------------------------
echo "Enabling multilib repo..."
sudo sed -i '/^\#\[multilib\]$/,/^\#Include/ s/^#//' /etc/pacman.conf
sudo pacman -Sy --needed

# -------------------------
# STAGE 0 – AUR Helper (yay)
# -------------------------
if ! command -v yay &>/dev/null; then
  echo "Installing yay..."
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  pushd /tmp/yay-bin && makepkg -si --noconfirm && popd
fi

# -------------------------
# STAGE 1 – Graphics & Audio (AMD Optimized)
# -------------------------
echo "Installing Graphics & Audio..."
sudo pacman -S --needed \
  linux-firmware \
  mesa lib32-mesa mesa-utils \
  libva-mesa-driver lib32-libva-mesa-driver \
  vulkan-radeon lib32-vulkan-radeon vulkan-tools \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal-hyprland \
  hyprpolkitagent \
  xdg-user-dirs brightnessctl pamixer

xdg-user-dirs-update

# -------------------------
# STAGE 2 – The Terminal Environment
# -------------------------
echo "Installing Zsh & Kitty..."
sudo pacman -S --needed \
  kitty zsh starship \
  zsh-syntax-highlighting zsh-autosuggestions \
  ttf-jetbrains-mono-nerd noto-fonts-emoji

sudo chsh -s /bin/zsh "$USER"

# -------------------------
# STAGE 3 – Hyprland Ecosystem & Notifications
# -------------------------
echo "Installing Hyprland & Dunst..."
sudo pacman -S --needed \
  hyprland waybar \
  grim slurp wl-clipboard \
  hyprpaper hypridle hyprlock \
  dunst libnotify \
  rofi-wayland \
  thunar thunar-archive-plugin thunar-volman \
  gvfs gvfs-mtp gvfs-smb \
  network-manager-applet \
  qt5-wayland qt6-wayland

# -------------------------
# STAGE 4 – Wallpapers & Assets
# -------------------------
echo "Downloading wallpaper..."
mkdir -p ~/Pictures/Wallpapers
# Downloading a clean, dark Arch-themed wallpaper
curl -L -o ~/Pictures/Wallpapers/default_wallpaper.png https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/master/wallpapers/ign_archlinux.png

# -------------------------
# STAGE 5 – Configuration Injection
# -------------------------
echo "Injecting configurations..."
mkdir -p ~/.config/hypr ~/.config/dunst ~/.config/kitty

# Zsh Config
cat <<EOF > ~/.zshrc
# Starship Init
eval "\$(starship init zsh)"

# Plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Aliases
alias v='nvim'
alias ff='fastfetch'
alias ls='ls --color=auto'
alias update='yay -Syu'
EOF

# Hyprpaper Config
cat <<EOF > ~/.config/hypr/hyprpaper.conf
preload = ~/Pictures/Wallpapers/default_wallpaper.png
wallpaper = ,~/Pictures/Wallpapers/default_wallpaper.png
splash = false
EOF

# Dunst Config (Clean & Rounded)
cat <<EOF > ~/.config/dunst/dunstrc
[global]
    font = JetBrainsMono Nerd Font 10
    frame_color = "#89b4fa"
    separator_color = frame
    offset = 20x20
    corner_radius = 10
    background = "#1e1e2e"
    foreground = "#cdd6f4"
EOF

# Kitty Config (Nerd Font Integration)
cat <<EOF > ~/.config/kitty/kitty.conf
font_family      JetBrainsMono Nerd Font
font_size        11.0
window_padding_width 10
background_opacity 0.9
EOF

# -------------------------
# STAGE 6 – Login Manager (greetd)
# -------------------------
echo "Configuring greetd..."
sudo pacman -S --needed greetd greetd-tuigreet

sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "greeter"
EOF

sudo systemctl enable greetd

# -------------------------
# STAGE 7 – Gaming & Extra Tools
# -------------------------
sudo pacman -S --needed \
  steam gamemode lib32-gamemode \
  mangohud lib32-mangohud \
  btop fastfetch neovim ripgrep fd \
  bluez bluez-utils ufw

sudo systemctl enable bluetooth
sudo systemctl enable ufw

# -------------------------
# STAGE 8 – The Master Hyprland Config
# -------------------------
echo "Generating hyprland.conf..."

cat <<EOF > ~/.config/hypr/hyprland.conf
# --- Monitors ---
monitor=,preferred,auto,1

# --- Programs ---
\$terminal = kitty
\$fileManager = thunar
\$menu = rofi -show drun

# --- Exec-Once ---
exec-once = systemctl --user start hyprpolkitagent
exec-once = dunst
exec-once = hyprpaper
exec-once = waybar
exec-once = nm-applet --indicator

# --- Input ---
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

# --- Visuals ---
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(89b4faff)
    col.inactive_border = rgba(585b70ff)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}

# --- Keybindings ---
\$mainMod = SUPER

bind = \$mainMod, Q, exec, \$terminal
bind = \$mainMod, C, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, E, exec, \$fileManager
bind = \$mainMod, V, togglefloating,
bind = \$mainMod, D, exec, \$menu
bind = \$mainMod, P, pseudo, # dwindle
bind = \$mainMod, J, togglesplit, # dwindle

# Move focus
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Switch workspaces
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3

# Laptop Hardware Keys (Volume/Brightness)
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindel = , XF86AudioLowerVolume, exec, pamixer -d 5
bindel = , XF86AudioMute, exec, pamixer -t
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Mouse Bindings
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow
EOF

# -------------------------
# Final Summary
# -------------------------
clear
echo "=== Install Complete ==="
echo "One final manual step: Edit your ~/.config/hypr/hyprland.conf and add:"
echo ""
echo "exec-once = systemctl --user start hyprpolkitagent"
echo "exec-once = dunst"
echo "exec-once = hyprpaper"
echo "exec-once = waybar"
echo "exec-once = nm-applet --indicator"
echo ""
echo "Rebooting in 10 seconds. Enjoy your new setup!"
sleep 10
reboot