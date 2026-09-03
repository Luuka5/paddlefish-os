#!/bin/sh
set -euo pipefail

IMAGE="${1:?Usage: install-server.sh <image-path-or-registry-ref>}"
SSH_KEY="${SSH_KEY:-}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root"
    exit 1
fi

if ! command -v podman >/dev/null 2>&1; then
    echo "Installing podman..."
    dnf install -y podman
fi

# Load from tar if it's a file, otherwise pull from registry
if [ -f "${IMAGE}" ]; then
    echo "Loading image from ${IMAGE}..."
    podman load -i "${IMAGE}"
    IMAGE_REF="$(podman images --format '{{.Repository}}:{{.Tag}}' | head -1)"
else
    echo "Pulling ${IMAGE}..."
    podman pull "${IMAGE}"
    IMAGE_REF="${IMAGE}"
fi

echo ""
echo "This will convert the running system to Paddlefish OS: ${IMAGE_REF}"
echo "  /boot will be reinitialized"
echo "  /etc and /var data will persist"
echo ""
printf "Continue? [y/N] "
read -r confirm
case "${confirm}" in
    [Yy]) ;;
    *) exit 0 ;;
esac

set -- bootc install to-existing-root
if [ -n "${SSH_KEY}" ]; then
    set -- "$@" --root-ssh-authorized-keys "${SSH_KEY}"
fi

podman run --rm --privileged \
    -v /dev:/dev \
    -v /var/lib/containers:/var/lib/containers \
    -v /:/target \
    --pid=host \
    --security-opt label=type:unconfined_t \
    "${IMAGE_REF}" \
    "$@"

echo ""
echo "Installation complete. Reboot to enter Paddlefish OS:"
echo "  sudo reboot"
