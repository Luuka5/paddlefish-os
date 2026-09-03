#!/bin/bash
set -euo pipefail

dnf5 copr enable -y yalter/niri

dnf5 install -y \
    niri \
    alacritty \
    fuzzel \
    xdg-desktop-portal-gnome \
    xwayland-satellite

dnf5 clean all
