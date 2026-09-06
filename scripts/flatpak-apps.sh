#!/bin/sh
set -euo pipefail

flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub io.github.flattool.Warehouse
