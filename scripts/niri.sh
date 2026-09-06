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
    xwayland-satellite

dnf5 clean all
