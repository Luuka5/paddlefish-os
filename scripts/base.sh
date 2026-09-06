#!/bin/sh
set -euo pipefail

dnf5 install -y \
    git \
    git-lfs \
    jujutsu \
    vim \
    neovim \
    fish \
    htop \
    curl \
    wget \
    unzip \
    podman \
    buildah \
    sudo \
    util-linux-user \
    fastfetch \
    zoxide

dnf5 clean all

# Default shell for any account created later on the machine.
useradd -D -s /usr/bin/fish
