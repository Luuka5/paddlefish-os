#!/bin/bash
set -euo pipefail

IMAGE="${1:?Usage: install-server.sh <image-path-or-registry-ref>}"
SSH_KEY="${SSH_KEY:-}"

if [[ $EUID -ne 0 ]]; then
    echo "Error: must run as root"
    exit 1
fi

if ! command -v podman &>/dev/null; then
    echo "Installing podman..."
    dnf install -y podman
fi

# Load from tar if it's a file, otherwise pull from registry
if [[ -f "${IMAGE}" ]]; then
    echo "Loading image from ${IMAGE}..."
    podman load -i "${IMAGE}"
    IMAGE_REF="$(podman images --format '{{.Repository}}:{{.Tag}}' | head -1)"
else
    echo "Pulling ${IMAGE}..."
    podman pull "${IMAGE}"
    IMAGE_REF="${IMAGE}"
fi

echo ""
echo "This will convert the running system to bootc: ${IMAGE_REF}"
echo "  /boot will be reinitialized"
echo "  /etc and /var data will persist"
echo ""
read -rp "Continue? [y/N] " confirm
[[ "${confirm}" =~ ^[Yy]$ ]] || exit 0

INSTALL_ARGS=(bootc install to-existing-root)
[[ -n "${SSH_KEY}" ]] && INSTALL_ARGS+=(--root-ssh-authorized-keys "${SSH_KEY}")

podman run --rm --privileged \
    -v /dev:/dev \
    -v /var/lib/containers:/var/lib/containers \
    -v /:/target \
    --pid=host \
    --security-opt label=type:unconfined_t \
    "${IMAGE_REF}" \
    "${INSTALL_ARGS[@]}"

echo ""
echo "Installation complete. Reboot to enter the new system:"
echo "  sudo reboot"
