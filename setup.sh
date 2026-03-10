#!/bin/bash
# Omarchy Dotfiles Setup Script

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting up dotfiles..."

# Hyprland
mkdir -p ~/.config/hypr/scripts
ln -sf "$DOTFILES_DIR/hypr/scripts/start-remote-displays.sh" ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/start-remote-displays.sh

# Waybar
mkdir -p ~/.config/waybar
ln -sf "$DOTFILES_DIR/waybar/config.jsonc" ~/.config/waybar/
ln -sf "$DOTFILES_DIR/waybar/style.css" ~/.config/waybar/

# Helix
mkdir -p ~/.config/helix/themes
ln -sf "$DOTFILES_DIR/helix/config.toml" ~/.config/helix/
ln -sf "$DOTFILES_DIR/helix/themes" ~/.config/helix/

# Omarchy hooks
mkdir -p ~/.config/omarchy/hooks
ln -sf "$DOTFILES_DIR/omarchy/hooks/theme-set" ~/.config/omarchy/hooks/
chmod +x ~/.config/omarchy/hooks/theme-set

# Misc
ln -sf "$DOTFILES_DIR/misc/default" ~/.config/uwsm/
ln -sf "$DOTFILES_DIR/misc/mimeapps.list" ~/.config/

# Generate helix theme for current omarchy theme
echo "Generating helix theme..."
~/.config/omarchy/hooks/theme-set "$(omarchy-theme-current 2>/dev/null || echo "Ethereal")"

echo "Done! Restart waybar with: omarchy-restart-waybar"
