#!/bin/sh
set -euo pipefail

AKMODNV_PATH=/tmp/akmods-nv-rpms

# Source version metadata from akmods build
source "${AKMODNV_PATH}"/kmods/nvidia-vars

# The base image ships mesa from negativo17-multimedia at epoch 1, whose
# per-arch publishes are asynchronous (i686 can land ahead of x86_64) and whose
# epoch bump stops dnf from falling back to Fedora's matching mesa -- causing
# multilib file conflicts. Align both arches to Fedora's epoch-0 mesa, which is
# published arch-atomically. distro-sync is required (epoch 1->0 downgrade).
if [[ "$(rpm -E '%{_arch}')" == "x86_64" ]]; then
    dnf5 distro-sync -y --repo=fedora --repo=updates \
        mesa-dri-drivers mesa-filesystem mesa-libEGL mesa-libGL mesa-libgbm mesa-vulkan-drivers
    dnf5 install -y --repo=fedora --repo=updates \
        mesa-dri-drivers.i686 mesa-filesystem.i686 mesa-libEGL.i686 \
        mesa-libGL.i686 mesa-libgbm.i686 mesa-vulkan-drivers.i686
fi

# Disable negativo17 multimedia to avoid conflicts during nvidia install
NEGATIVO17_MULT_PREV_ENABLED=N
if dnf5 repolist --enabled | grep -q "fedora-multimedia"; then
    NEGATIVO17_MULT_PREV_ENABLED=Y
    dnf5 config-manager setopt fedora-multimedia.enabled=0
fi

# Get kernel version from the base image
KERNEL_VERSION="$(rpm -q --queryformat='%{evr}.%{arch}' kernel-core)"

# Install NVIDIA packages: pre-built RPMs from akmods + packages from negativo17 repos
NVIDIA_RPMS=(
    "${AKMODNV_PATH}"/nvidia/*."$(rpm -E '%{_arch}')".rpm
    "${AKMODNV_PATH}"/nvidia/*.noarch.rpm
    nvidia-container-toolkit
    egl-wayland
    libva-nvidia-driver
    "${AKMODNV_PATH}"/kmods/kmod-nvidia-"${KERNEL_VERSION}"-"${NVIDIA_AKMOD_VERSION}"."${DIST_ARCH}".rpm
)
if [[ "$(rpm -E '%{_arch}')" == "x86_64" ]]; then
    NVIDIA_RPMS+=(
        "${AKMODNV_PATH}"/nvidia/*.i686.rpm
    )
fi
dnf5 install -y "${NVIDIA_RPMS[@]}"

# Verify kmod version matches driver version
KMOD_VERSION="$(rpm -q --queryformat '%{VERSION}' kmod-nvidia)"
DRIVER_VERSION="$(rpm -q --queryformat '%{VERSION}' nvidia-driver)"
if [ "$KMOD_VERSION" != "$DRIVER_VERSION" ]; then
    echo "Error: kmod-nvidia version ($KMOD_VERSION) does not match nvidia-driver version ($DRIVER_VERSION)"
    exit 1
fi

# Disable nvidia repos (keep disabled for runtime)
dnf5 config-manager setopt fedora-nvidia*.enabled=0 nvidia-container-toolkit.enabled=0

# Re-enable multimedia if it was previously enabled
if [[ "${NEGATIVO17_MULT_PREV_ENABLED}" = "Y" ]]; then
    dnf5 config-manager setopt fedora-multimedia.enabled=1
fi

# nvidia-settings ships an X11-only autostart entry that runs
# `nvidia-settings --load-config-only`. There is no X server in the Wayland
# niri session, so it fails on every login. Remove it.
rm -f /etc/xdg/autostart/nvidia-settings-load.desktop \
      /usr/etc/xdg/autostart/nvidia-settings-load.desktop

# Enable systemd services
systemctl enable nvidia-cdi-refresh.service nvidia-cdi-refresh.path nvidia-persistenced.service

# Install SELinux policy for container toolkit
semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp

# Force driver load in initramfs (fixes black screen on boot)
sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf
# Pre-load iGPU for chromium hardware acceleration
sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf

# Regenerate initramfs
QUALIFIED_KERNEL="$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

dnf5 clean all
