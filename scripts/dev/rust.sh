#!/bin/sh
set -euo pipefail

. /tmp/scripts/dev/versions.env

# Build dependencies for Bevy on Linux (Fedora), plus the fast-linker stack.
# Runtime graphics packages live in gui.sh.
dnf5 install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    ninja-build \
    pkgconf-pkg-config \
    clang \
    clang-tools-extra \
    lld \
    lldb \
    mold \
    libX11-devel \
    libXcursor-devel \
    libXi-devel \
    libXrandr-devel \
    libxkbcommon-devel \
    libxkbcommon-x11-devel \
    wayland-devel \
    alsa-lib-devel \
    systemd-devel

dnf5 clean all

# rustup with the default profile plus the components a Rust dev setup wants.
# Toolchains live system-wide under /usr/local; CARGO_HOME is left to the user
# so the crate cache lands in the per-project home volume.
export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y \
    --no-modify-path \
    --profile default \
    --default-toolchain "${RUST_TOOLCHAIN}" \
    -c clippy \
    -c rustfmt \
    -c rust-analyzer

# Expose the rustup shims on PATH for every user.
for bin in /usr/local/cargo/bin/*; do
    ln -sf "$bin" "/usr/local/bin/$(basename "$bin")"
done

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5
