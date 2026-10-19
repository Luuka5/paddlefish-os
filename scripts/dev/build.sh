#!/bin/sh
set -euo pipefail

# Build a Paddlefish OS development container image locally.
#
# Usage: scripts/dev/build.sh [core|gui|nvidia|all]
#
# The paddlefish-dev runner builds images on demand; this script is for
# building/refreshing them explicitly.

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "${here}/../.." && pwd)

FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"
BASE_IMAGE="${BASE_IMAGE:-registry.fedoraproject.org/fedora:${FEDORA_MAJOR_VERSION}}"

build_variant() {
    variant=$1
    image="localhost/paddlefish-dev-${variant}"
    echo "Building ${image} (Fedora ${FEDORA_MAJOR_VERSION})..."
    podman build \
        --build-arg "FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION}" \
        --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
        --build-arg "DEV_VARIANT=${variant}" \
        -f "${root}/Containerfile.dev" \
        -t "${image}:latest" \
        "${root}"
    echo "Built ${image}:latest"
}

case "${1:-all}" in
    core) build_variant core ;;
    gui) build_variant gui ;;
    nvidia) build_variant nvidia ;;
    all)
        build_variant core
        build_variant gui
        build_variant nvidia
        ;;
    *)
        echo "Unknown variant: $1 (available: core, gui, nvidia, all)" >&2
        exit 1
        ;;
esac
