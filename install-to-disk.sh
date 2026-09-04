#!/bin/sh
set -eu

# Install a Paddlefish OS image onto a whole disk, from any running Linux with
# podman (e.g. a Fedora live USB, or the bundled Paddlefish live media). The OS
# image is installed with the bootc-native installer; the disk is never touched
# without an explicit typed-YES confirmation.
#
# When run from the bundled media, the OS image is loaded from the local tar in
# <media>/images/ (no network needed); otherwise it is pulled from the registry.
# --target-imgref always points at the registry ref so `bootc upgrade` works
# later when the machine is online.
#
# Usage: install-to-disk.sh [desktop|laptop|server]
#   PADDLEFISH_REGISTRY=<ghcr.io/owner> ./install-to-disk.sh desktop
#   PADDLEFISH_MEDIA=/path/to/paddlefish ./install-to-disk.sh desktop

VARIANT="${1:-desktop}"
case "${VARIANT}" in
    desktop|laptop|server) ;;
    *) echo "Unknown variant: ${VARIANT} (available: desktop, laptop, server)" >&2; exit 1 ;;
esac

REGISTRY="${PADDLEFISH_REGISTRY:-ghcr.io/luuka5}"
TARGET="${REGISTRY}/paddlefish-os-${VARIANT}:latest"

# Locate the bundled media (repo + image tars), if present.
MEDIA="${PADDLEFISH_MEDIA:-}"
if [ -z "${MEDIA}" ]; then
    for d in /paddlefish /run/initramfs/live/paddlefish; do
        if [ -d "${d}/images" ]; then
            MEDIA="${d}"
            break
        fi
    done
fi

IMAGE_REF="${TARGET}"
BUNDLED=""
if [ -n "${MEDIA}" ] && [ -f "${MEDIA}/images/paddlefish-os-${VARIANT}.tar" ]; then
    BUNDLED="${MEDIA}/images/paddlefish-os-${VARIANT}.tar"
    IMAGE_REF="localhost/paddlefish-os-${VARIANT}:latest"
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root" >&2
    exit 1
fi

if ! command -v podman >/dev/null 2>&1; then
    echo "Error: podman is required (e.g. on a Fedora live session: dnf install -y podman)" >&2
    exit 1
fi

# Best-effort guard against wiping the running live medium.
SELF="$(findmnt -no SOURCE / 2>/dev/null || true)"
case "$SELF" in
    /dev/*)
        SELF_DISK="$(lsblk -no PKNAME "$SELF" 2>/dev/null || printf '%s' "$SELF")"
        ;;
    *) SELF_DISK= ;;
esac

echo "Paddlefish OS installer"
if [ -n "${BUNDLED}" ]; then
    echo "Image to install: ${TARGET} (bundled on this media)"
else
    echo "Image to install: ${TARGET} (from registry)"
fi
echo
echo "Available whole disks:"
lsblk -dno PATH,SIZE,MODEL,TRAN,TYPE | awk '$NF == "disk" { print }'
echo
printf 'Target disk (e.g. /dev/nvme0n1): '
read -r DISK

if ! lsblk -dno PATH,TYPE | awk '$NF == "disk" { print $1 }' | grep -Fxq "$DISK" || [ ! -b "$DISK" ]; then
    echo "Error: '$DISK' is not a whole disk. Aborting." >&2
    exit 1
fi
if [ -n "$SELF_DISK" ] && [ "$SELF_DISK" = "$DISK" ]; then
    echo "Error: '$DISK' is the disk the live system is running from. Refusing." >&2
    exit 1
fi

echo
echo "This will ERASE ALL DATA on ${DISK} and install:"
echo "  ${TARGET}"
printf 'Type YES to continue: '
read -r CONFIRM
[ "$CONFIRM" = "YES" ] || {
    echo "Aborted."
    exit 1
}

echo
if [ -n "${BUNDLED}" ]; then
    echo "Loading ${BUNDLED}..."
    podman load -i "${BUNDLED}"
else
    echo "Pulling ${TARGET}..."
    podman pull "${TARGET}"
fi

echo
echo "Installing to ${DISK}..."
podman run --rm --privileged \
    --pid=host \
    --ipc=host \
    -v /var/lib/containers:/var/lib/containers \
    -v /dev:/dev \
    --security-opt label=type:unconfined_t \
    "${IMAGE_REF}" \
    bootc install to-disk --wipe --target-imgref "${TARGET}" "${DISK}"

echo
echo "Install complete."
echo "Reboot, then log in as 'user' and set a new password when prompted."
