#!/bin/sh
set -euo pipefail

# Bake the default interactive user BEFORE the package transaction.
# systemd ships rpm file-triggers that run systemd-sysusers over
# /usr/lib/sysusers.d during dnf transactions; doing this first means the
# trigger finds 'user' already present and skips it.
# The shell is left at the image default here (fish isn't installed yet) and
# set to fish after the dnf step below.
printf '\nCREATE_MAIL_SPOOL=no\n' >> /etc/default/useradd
useradd -u 1000 -m -G wheel user
printf 'user:paddlefish\n' | chpasswd

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
    buildah \
    sudo

dnf5 clean all

# Set fish as the default shell for user accounts
useradd -D -s /usr/bin/fish
usermod -s /usr/bin/fish user

# Point the baked user's config at the image-managed tree in /etc/skel.
# /etc is 3-way merged on bootc upgrades, so image updates refresh these
# configs until the user edits a file through the symlink (then it is treated
# as machine-local and retained).
USER_HOME="$(getent passwd user | cut -d: -f6)"
rm -rf "${USER_HOME}/.config"
ln -s /etc/skel/.config "${USER_HOME}/.config"
chown -R user:user /etc/skel/.config

# fish is the default shell; drop the bash dotfiles copied from the base
# image's /etc/skel so the baked home stays minimal in /var.
rm -f "${USER_HOME}/.bash_logout" "${USER_HOME}/.bash_profile" "${USER_HOME}/.bashrc"

systemctl enable user-password-setup.service
