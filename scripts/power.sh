#!/bin/sh
set -euo pipefail

# TLP manages power and battery charge thresholds; tlp-pd provides the
# PowerProfiles D-Bus interface that power-profiles-daemon used to provide
# (so waybar's power-profiles module keeps working).
dnf5 install -y \
    tlp \
    tlp-pd

dnf5 clean all

# Limit laptop battery charging to 80% to prolong its lifespan. Charging
# resumes once the battery drops below the start threshold (75%).
cat > /etc/tlp.d/00-charge-threshold.conf <<'EOF'
STOP_CHARGE_THRESH_BAT0=80
START_CHARGE_THRESH_BAT0=75
EOF
