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
    wdisplays \
    xwayland-satellite

# shikane is only built for f43 in the sand-head/packages COPR. Its spurious
# "wayland-protocols" dependency was merged into wayland-protocols-devel in
# f44, so install the f43 RPM directly with --nodeps (all real deps resolve).
curl -sL -o /tmp/shikane.rpm https://download.copr.fedorainfracloud.org/results/sand-head/packages/fedora-43-x86_64/10094150-shikane/shikane-1.0.1-1.fc43.x86_64.rpm
rpm -Uvh --nodeps /tmp/shikane.rpm
rm -f /tmp/shikane.rpm

dnf5 clean all

# FiraCode Nerd Font: patched Fira Code with icon glyphs.
curl -sL -o /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/FiraCode.zip
unzip -q /tmp/FiraCode.zip -d /tmp/firacode 'FiraCodeNerdFont-*.ttf' 'FiraCodeNerdFontMono-*.ttf'
install -d -m 0755 /usr/share/fonts/fira-code-nerd-fonts
install -m 0644 /tmp/firacode/*.ttf /usr/share/fonts/fira-code-nerd-fonts/
fc-cache -f
rm -rf /tmp/FiraCode.zip /tmp/firacode
