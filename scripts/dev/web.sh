#!/bin/sh
set -euo pipefail

. /tmp/scripts/dev/versions.env

# Node.js toolchain from Fedora; pnpm/typescript/tailwind come from npm so the
# versions are pinned in versions.env rather than tied to the distro.
dnf5 install -y nodejs npm
dnf5 clean all

npm install -g \
    "pnpm@${PNPM_VERSION}" \
    "typescript@${TYPESCRIPT_VERSION}" \
    "@tailwindcss/cli@${TAILWIND_VERSION}"

# Bun ships no Fedora package; use its installer pinned to a release. It needs
# unzip, which base.sh installs. BUN_INSTALL must be set on the installer
# process itself (the env assignment has to be on bash, not the curl side of
# the pipe) so bun lands in /usr/local/bin instead of ~/.bun.
curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash -s "bun-v${BUN_VERSION}"

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5
