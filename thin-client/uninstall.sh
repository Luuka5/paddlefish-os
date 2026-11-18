#!/usr/bin/env bash
set -euo pipefail

readonly STATE_DIR="/var/lib/paddlefish-thin-client"
readonly LEGACY_HOOK="/etc/profile.d/paddlefish-niri.sh"
readonly LEGACY_WRAPPER="/usr/libexec/paddlefish/niri-session"

DRY_RUN=0
PURGE_CONFIGS=0
CLEAN_TEMP=0
LIST_PACKAGES=0
TARGET_USER="${SUDO_USER:-}"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

log() {
    printf '==> %s\n' "$*"
}

usage() {
    cat <<'EOF'
Usage: sudo ./uninstall.sh [options]

Removes files installed by thin-client/install.sh. Packages and user
configuration are kept unless explicitly requested.

Options:
  --dry-run         Show what would be removed without changing anything
  --purge-configs   Remove copied niri, foot, fuzzel, and GTK configs
  --clean-temp      Remove leftover /var/tmp/niri-build.* directories
  --list-packages   Print package-review hints; does not remove packages
  --user USER       User whose niri service is stopped or whose configs are purged
  -h, --help        Show this help
EOF
}

run() {
    if (( DRY_RUN )); then
        printf 'would: '
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

require_root() {
    [[ "$(id -u)" -eq 0 ]] || die "run as root (sudo $0 ...)"
}

detect_target_user() {
    local user="${TARGET_USER:-}"
    if [[ -z "$user" || "$user" == "root" ]]; then
        user="$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)"
    fi
    [[ -n "$user" ]] || return 1
    printf '%s\n' "$user"
}

remove_file() {
    local path="$1"

    [[ -e "$path" || -L "$path" ]] || return 0

    if dpkg -S "$path" >/dev/null 2>&1; then
        warn "skipping package-owned file: $path"
        return 0
    fi

    log "Removing $path"
    run rm -f -- "$path"
}

remove_dir_if_empty() {
    local path="$1"

    [[ -d "$path" ]] || return 0

    if (( DRY_RUN )); then
        printf 'would: rmdir --ignore-fail-on-non-empty %q\n' "$path"
    else
        rmdir --ignore-fail-on-non-empty "$path" 2>/dev/null || true
    fi
}

stop_niri_service() {
    local user="$1"

    [[ -n "$user" ]] || return 0

    log "Stopping niri user service for $user"
    if (( DRY_RUN )); then
        printf 'would: timeout 5s systemctl --user --machine=%s@.host stop niri.service\n' "$user"
        return 0
    fi

    timeout 5s systemctl --user --machine="${user}@.host" stop niri.service >/dev/null 2>&1 || true
}

remove_system_files() {
    local path

    for path in \
        /usr/bin/niri \
        /usr/bin/niri-session \
        /usr/lib/systemd/user/niri.service \
        /usr/lib/systemd/user/niri-shutdown.target \
        /usr/share/wayland-sessions/niri.desktop \
        /usr/share/xdg-desktop-portal/niri-portals.conf \
        "$LEGACY_HOOK" \
        "$LEGACY_WRAPPER"; do
        remove_file "$path"
    done

    remove_dir_if_empty /usr/libexec/paddlefish
}

remove_state() {
    [[ -e "$STATE_DIR" ]] || return 0

    log "Removing state directory $STATE_DIR"
    run rm -rf -- "$STATE_DIR"
}

remove_temp() {
    local path

    for path in /var/tmp/niri-build.*; do
        [[ -e "$path" ]] || continue
        log "Removing temporary build directory $path"
        run rm -rf -- "$path"
    done
}

purge_configs() {
    local user="$1"
    local target_home="$2"
    local root rel dir
    local -a roots=(/etc/skel)

    if [[ -n "$target_home" && -d "$target_home" ]]; then
        roots+=("$target_home")
    fi

    for root in "${roots[@]}"; do
        [[ -d "$root" ]] || continue

        for rel in \
            .config/niri/config.kdl \
            .config/foot/foot.ini \
            .config/fuzzel/fuzzel.ini \
            .config/gtk-3.0/settings.ini \
            .config/gtk-4.0/settings.ini; do
            remove_file "$root/$rel"
        done

        for dir in \
            .config/niri \
            .config/foot \
            .config/fuzzel \
            .config/gtk-3.0 \
            .config/gtk-4.0; do
            remove_dir_if_empty "$root/$dir"
        done
    done

    if [[ -z "$user" ]]; then
        warn "no regular user found; only /etc/skel configs were considered"
    fi
}

list_packages() {
    log "Packages are not removed automatically"
    cat <<'EOF'
Review APT_PACKAGES and BUILD_PACKAGES in thin-client/install.sh before
removing anything, because some packages may be used by the rest of the system.

Runtime packages most likely added by this installer:
  foot fuzzel firefox-esr fonts-firacode fonts-dejavu-core fontconfig
  libgl1-mesa-dri libegl1 libegl-mesa0 libgbm1 libxcb-dri2-0 libxcb-dri3-0
  libxcb-present0 libxcb-randr0 libxcb-shm0 libxcb-sync1 libxcb-xfixes0
  libxcb1 libx11-xcb1 libxshmfence1 libdisplay-info2 libseat1 libinput10
  libxkbcommon0 libwayland-server0 libwayland-client0 libpixman-1-0
  libcairo2 libpango-1.0-0 libglib2.0-0t64 libpipewire-0.3-0 libdbus-1-3
  libudev1 libdrm2 bluez network-manager wpasupplicant wireless-regdb
  polkitd libpam-systemd pipewire pipewire-pulse wireplumber
  xdg-desktop-portal xdg-desktop-portal-gtk
EOF
}

parse_args() {
    while (($#)); do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                ;;
            --purge-configs)
                PURGE_CONFIGS=1
                ;;
            --clean-temp)
                CLEAN_TEMP=1
                ;;
            --list-packages)
                LIST_PACKAGES=1
                ;;
            --user)
                [[ $# -ge 2 ]] || die "--user requires an argument"
                TARGET_USER="$2"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "unknown argument: $1"
                ;;
        esac
        shift
    done
}

main() {
    local user target_home

    parse_args "$@"

    if (( LIST_PACKAGES )); then
        list_packages
        exit 0
    fi

    require_root

    user="$(detect_target_user || true)"
    if [[ -n "$user" ]]; then
        id -u "$user" >/dev/null 2>&1 || die "user not found: $user"
        target_home="$(getent passwd "$user" | awk -F: '{print $6}')"
        stop_niri_service "$user"
    else
        target_home=""
    fi

    remove_system_files
    remove_state

    if (( CLEAN_TEMP )); then
        remove_temp
    fi

    if (( PURGE_CONFIGS )); then
        purge_configs "$user" "$target_home"
    fi

    if (( DRY_RUN )); then
        log "Dry run complete; nothing was changed"
    else
        log "Uninstall complete"
    fi
    log "Packages were not removed; use --list-packages for review hints"
}

main "$@"
