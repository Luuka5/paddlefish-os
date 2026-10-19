#!/bin/sh
set -euo pipefail

# Go toolchain and its language server.
dnf5 install -y \
    golang \
    gopls

dnf5 clean all

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5
