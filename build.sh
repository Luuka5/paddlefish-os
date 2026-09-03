#!/bin/sh
set -euo pipefail

FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"

build_variant() {
    local name=$1 base=$2 nvidia=$3 desktop=$4
    local image="paddlefish-os-${name}"
    echo "Building ${name} (Fedora ${FEDORA_MAJOR_VERSION}, nvidia=${nvidia}, desktop=${desktop})..."
    podman build \
        --build-arg "FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION}" \
        --build-arg "BASE_IMAGE=${base}" \
        --build-arg "IMAGE_NAME=${name}" \
        --build-arg "BUILD_NVIDIA=${nvidia}" \
        --build-arg "BUILD_DESKTOP=${desktop}" \
        -f Containerfile \
        -t "${image}:latest" \
        .
    echo "Built ${image}:latest"
}

case "${1:-all}" in
    desktop)
        build_variant desktop "ghcr.io/ublue-os/base-main:latest" Y Y
        ;;
    laptop)
        build_variant laptop "ghcr.io/ublue-os/base-main:latest" N Y
        ;;
    server)
        build_variant server "quay.io/fedora/fedora-bootc:${FEDORA_MAJOR_VERSION}" N N
        ;;
    all)
        build_variant desktop "ghcr.io/ublue-os/base-main:latest" Y Y
        build_variant laptop  "ghcr.io/ublue-os/base-main:latest" N Y
        build_variant server  "quay.io/fedora/fedora-bootc:${FEDORA_MAJOR_VERSION}" N N
        ;;
    *)
        echo "Unknown variant: $1 (available: desktop, laptop, server, all)"
        exit 1
        ;;
esac
