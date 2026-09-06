#!/bin/sh
set -euo pipefail

dnf5 install -y flatpak
dnf5 clean all

flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub io.github.flattool.Warehouse
flatpak override --system --env=GTK_THEME=Adwaita:dark
