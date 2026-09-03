#!/bin/sh
set -euo pipefail

FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"

VARIANTS=("desktop" "laptop" "server")

build_variant() {
    local variant=$1
    local image="bootc-${variant}"
    echo "Building ${variant} (Fedora ${FEDORA_MAJOR_VERSION})..."
    sudo podman build \
        --build-arg "FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION}" \
        -f "Containerfile.${variant}" \
        -t "${image}:latest" \
        .
    echo "Built ${image}:latest"
}

if [[ $# -gt 0 ]]; then
    variant=$1
    if [[ ! " ${VARIANTS[*]} " =~ " ${variant} " ]]; then
        echo "Unknown variant: ${variant}"
        echo "Available: ${VARIANTS[*]}"
        exit 1
    fi
    build_variant "$variant"
else
    for variant in "${VARIANTS[@]}"; do
        build_variant "$variant"
    done
fi
