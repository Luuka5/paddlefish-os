#!/bin/sh
set -euo pipefail

IMAGE="${1:?Usage: build-iso.sh <image-name:tag>}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"

# Ensure local images resolve correctly inside bootc-image-builder
if [[ "${IMAGE}" != *"/"* ]]; then
    IMAGE="localhost/${IMAGE}"
fi

mkdir -p "${OUTPUT_DIR}"

echo "Building Anaconda ISO for ${IMAGE}..."
echo "Output: ${OUTPUT_DIR}/"

sudo podman run --rm -it --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "${OUTPUT_DIR}":/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type anaconda-iso \
    "${IMAGE}"

echo "ISO built in ${OUTPUT_DIR}/"
