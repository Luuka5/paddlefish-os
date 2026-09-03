#!/bin/bash
set -euo pipefail

AKMODNV_PATH=/tmp/akmods-nv-rpms

# Source version metadata from akmods build
source "${AKMODNV_PATH}"/kmods/nvidia-vars

# Disable rpmfusion repos if they exist (safety check)
if dnf5 repolist --all | grep -q rpmfusion; then
    dnf5 config-manager setopt "rpmfusion*".enabled=0
fi
dnf5 config-manager setopt fedora-cisco-openh264.enabled=0

# Install ublue-os-nvidia-addons (provides negativo17 nvidia repos, SELinux policy, systemd presets)
dnf5 install -y "${AKMODNV_PATH}"/ublue-os/ublue-os-nvidia-addons-*.rpm

# Enable negativo17 nvidia repos (installed by ublue-os-nvidia-addons, disabled by default)
dnf5 config-manager setopt fedora-nvidia*.enabled=1 nvidia-container-toolkit.enabled=1
