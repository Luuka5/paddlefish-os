#!/bin/bash
set -euo pipefail

dnf5 install -y \
    git \
    vim \
    neovim \
    fish \
    htop \
    curl \
    wget \
    unzip \
    podman \
    buildah

dnf5 clean all

# Set fish as default shell for new users
useradd -D -s /usr/bin/fish
