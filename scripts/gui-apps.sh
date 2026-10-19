#!/bin/sh
set -euo pipefail

dnf5 install -y \
    firefox \
    nautilus

# Required for file transfer to android phones
dnf5 install -y \
    gvfs-mtp \
    jmtpfs

dnf5 clean all
