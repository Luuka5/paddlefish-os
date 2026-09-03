#!/bin/sh
set -euo pipefail

VARIANT="${1:?Usage: build-iso.sh <variant> (desktop|laptop)}"
IMAGE="localhost/paddlefish-os-${VARIANT}:latest"
OUT_DIR="paddlefish-os-${VARIANT}-iso"

mkdir -p "${OUT_DIR}"

echo "Building Anaconda ISO for ${IMAGE}..."

sudo podman run --rm --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "$(realpath "${OUT_DIR}")":/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type anaconda-iso \
    "${IMAGE}"

sudo mv "${OUT_DIR}/bootiso/install.iso" "${OUT_DIR}/paddlefish-os-${VARIANT}.iso"
sudo chown "$(id -u):$(id -g)" "${OUT_DIR}/paddlefish-os-${VARIANT}.iso"

echo "ISO built: ${OUT_DIR}/paddlefish-os-${VARIANT}.iso"
