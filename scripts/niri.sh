#!/bin/sh
set -euo pipefail

dnf5 copr enable -y yalter/niri

dnf5 install -y \
    niri \
    foot \
    fuzzel \
    waybar \
    swaylock \
    pavucontrol \
    network-manager-applet \
    NetworkManager-tui \
    bluez \
    greetd \
    playerctl \
    brightnessctl \
    xdg-desktop-portal-gnome \
    pipewire \
    pipewire-pulse \
    wireplumber \
    xwayland-satellite

dnf5 clean all

# FiraCode Nerd Font: patched Fira Code with icon glyphs.
curl -sL -o /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.zip
unzip -q /tmp/FiraCode.zip -d /tmp/firacode 'FiraCodeNerdFont-*.ttf' 'FiraCodeNerdFontMono-*.ttf'
install -d -m 0755 /usr/share/fonts/fira-code-nerd-fonts
install -m 0644 /tmp/firacode/*.ttf /usr/share/fonts/fira-code-nerd-fonts/
fc-cache -f
rm -rf /tmp/FiraCode.zip /tmp/firacode
