#!/bin/sh
set -euo pipefail

# NVIDIA variant glue. The driver libraries themselves are injected at runtime
# from the host via CDI (--device nvidia.com/gpu=all), provisioned by the
# desktop-nvidia image's nvidia-container-toolkit. The container only needs the
# loader/GLVND stack and the EGL Wayland platform.
dnf5 install -y \
    egl-wayland \
    vulkan-loader \
    vulkan-tools \
    libglvnd \
    libglvnd-egl

dnf5 clean all

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5
