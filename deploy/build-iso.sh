#!/bin/sh
set -euo pipefail

VARIANT="${1:?Usage: build-iso.sh <variant> (desktop|laptop)}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
IMAGE="localhost/paddlefish-os-${VARIANT}:latest"

mkdir -p "${OUTPUT_DIR}"

echo "Building Anaconda ISO for ${IMAGE}..."

sudo podman run --rm --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "$(realpath "${OUTPUT_DIR}")":/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type anaconda-iso \
    "${IMAGE}"

# bootc-image-builder outputs to a subdirectory
ISO_SRC=$(find "${OUTPUT_DIR}" -name '*.iso' -type f | head -1)
if [ -n "${ISO_SRC}" ]; then
    mv "${ISO_SRC}" "${OUTPUT_DIR}/paddlefish-os-${VARIANT}.iso"
    echo "ISO built: ${OUTPUT_DIR}/paddlefish-os-${VARIANT}.iso"
else
    echo "Error: no ISO found in ${OUTPUT_DIR}"
    exit 1
fi
