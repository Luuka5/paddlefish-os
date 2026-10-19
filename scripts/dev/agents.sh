#!/bin/sh
set -euo pipefail

. /tmp/scripts/dev/versions.env

# AI coding agents, pinned. Installed after web.sh so npm/node are present.
npm install -g \
    "opencode-ai@${OPENCODE_VERSION}" \
    "@earendil-works/pi-coding-agent@${PI_VERSION}"
