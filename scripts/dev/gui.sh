#!/bin/sh
set -euo pipefail

# The Fedora release repo carries an older mesa build than updates, and mesa's
# subpackages require matching EVRs. Installing a subset then makes dnf5 try to
# keep both versions ("cannot install both mesa-dri-drivers ... from fedora and
# ... from updates"). Sync the installed set to the enabled repos first so the
# whole mesa stack moves together (same approach as scripts/nvidia.sh).
dnf5 distro-sync -y --refresh

# GUI/GPU userspace for Wayland and XWayland. The kernel driver stays on the
# host; the container only needs matching userspace.
#
# mesa-dri-drivers provides radeonsi (AMD), iris/crocus (Intel) and llvmpipe
# (software); mesa-vulkan-drivers provides radv (AMD), anv (Intel) and
# lavapipe (software). This is what lets an AMD/Intel integrated laptop run
# Bevy et al. with --device /dev/dri --group-add keep-groups.
dnf5 install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    mesa-va-drivers \
    mesa-libGL \
    mesa-libEGL \
    mesa-libgbm \
    mesa-libglapi \
    libglvnd \
    libglvnd-egl \
    libglvnd-gles \
    vulkan-loader \
    vulkan-tools \
    libdrm \
    libwayland-client \
    libwayland-server \
    libwayland-cursor \
    libwayland-egl \
    libxkbcommon \
    libxkbcommon-x11 \
    xorg-x11-xauth \
    alsa-lib \
    pipewire-libs \
    pulseaudio-libs \
    dbus-libs \
    fontconfig \
    mesa-libGL-devel \
    mesa-libEGL-devel \
    mesa-libgbm-devel \
    vulkan-loader-devel

dnf5 clean all

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5
