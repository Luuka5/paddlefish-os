#!/bin/sh
set -euo pipefail

# C and C++ toolchain. clang-tools-extra provides clangd, used by the nvim
# config; lldb/gdb provide debuggers.
dnf5 install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    ninja-build \
    pkgconf-pkg-config \
    autoconf \
    automake \
    bison \
    flex \
    clang \
    clang-tools-extra \
    lld \
    lldb \
    gdb \
    strace

dnf5 clean all

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5
