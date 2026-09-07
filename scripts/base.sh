#!/bin/sh
set -euo pipefail

dnf5 install -y \
    git \
    git-lfs \
    vim \
    neovim \
    fish \
    htop \
    curl \
    wget \
    unzip \
    podman \
    podman-compose \
    buildah \
    sudo \
    util-linux-user \
    fastfetch \
    zoxide \
    fzf \
    fd-find \
    ripgrep \
    wl-clipboard

# jujutsu (jj) is packaged in the aldantanneo/jj-vcs COPR, which tracks the
# latest upstream release. Enable it via a repo file so this works on every
# base image (some, e.g. fedora-bootc, lack the dnf5 copr plugin).
cat > /etc/yum.repos.d/aldantanneo-jj-vcs.repo <<'EOF'
[copr:copr.fedorainfracloud.org:aldantanneo:jj-vcs]
name=Copr repo for jj-vcs owned by aldantanneo
baseurl=https://download.copr.fedorainfracloud.org/results/aldantanneo/jj-vcs/fedora-$releasever-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/aldantanneo/jj-vcs/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

dnf5 install -y jj-cli

dnf5 clean all

# Default shell for any account created later on the machine.
useradd -D -s /usr/bin/fish
