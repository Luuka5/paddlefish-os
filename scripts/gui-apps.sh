#!/bin/bash
set -euo pipefail

dnf5 install -y \
    firefox

dnf5 clean all
