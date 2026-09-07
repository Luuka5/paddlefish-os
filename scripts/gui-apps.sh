#!/bin/sh
set -euo pipefail

dnf5 install -y \
    firefox \
    nautilus

dnf5 clean all
