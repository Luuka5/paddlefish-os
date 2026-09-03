#!/bin/bash
set -euo pipefail

dnf5 install -y \
    git \
    vim \
    htop \
    curl \
    wget \
    unzip \
    podman \
    buildah

dnf5 clean all
