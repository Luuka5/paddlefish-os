#!/usr/bin/env bash
set -euo pipefail

readonly NIRI_VERSION="26.04"
readonly NIRI_TAG="v${NIRI_VERSION}"
readonly NIRI_COMMIT="8ed0da44d974c32c6877d2f4630c314da0717ecb"
readonly NIRI_SOURCE_URL="https://github.com/niri-wm/niri/archive/refs/tags/${NIRI_TAG}.tar.gz"
readonly NIRI_SOURCE_SHA256="134c602d8e0d53413a52d6cd58f9ce7e79a07d03288ee0a51ba1abd5db1b1ad9"
readonly NIRI_VENDOR_URL="https://github.com/niri-wm/niri/releases/download/${NIRI_TAG}/niri-${NIRI_VERSION}-vendored-dependencies.tar.xz"
readonly NIRI_VENDOR_SHA256="407c525cd78710e72455c48741756857ca47dc32910a42f82cd40992a34beed6"
readonly SMITHAY_REV="ff5fa7df392cecfba049ffed55cdaa4e98a8e7ef"

readonly NWG_DISPLAYS_VERSION="0.5.0"
readonly NWG_DISPLAYS_URL="https://github.com/nwg-piotr/nwg-displays/archive/refs/tags/v${NWG_DISPLAYS_VERSION}.tar.gz"
readonly NWG_DISPLAYS_SHA256="28dfe825e7a6a18df62d36aa1b6b7d232ab86b7f06f99994ad00c04e8b4ccfbc"

readonly STATE_DIR="/var/lib/paddlefish-thin-client"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly APT_PACKAGES=(
    ca-certificates
    openssh-client
    procps
    foot
    fuzzel
    firefox-esr
    fonts-firacode
    fonts-dejavu-core
    fontconfig
    libgl1-mesa-dri
    libegl1
    libegl-mesa0
    libgbm1
    libxcb-dri2-0
    libxcb-dri3-0
    libxcb-present0
    libxcb-randr0
    libxcb-shm0
    libxcb-sync1
    libxcb-xfixes0
    libxcb1
    libx11-xcb1
    libxshmfence1
    libdisplay-info2
    libseat1
    libinput10
    libxkbcommon0
    libwayland-server0
    libwayland-client0
    libpixman-1-0
    libcairo2
    libpango-1.0-0
    libglib2.0-0t64
    libpipewire-0.3-0
    libdbus-1-3
    libudev1
    libdrm2
    bluez
    network-manager
    wpasupplicant
    wireless-regdb
    polkitd
    libpam-systemd
    pavucontrol
    pipewire
    pipewire-pulse
    wireplumber
    dbus-user-session
    xdg-desktop-portal-gtk
    adwaita-icon-theme
    python3
    python3-gi
    gir1.2-gtk-3.0
    gir1.2-gtklayershell-0.1
    python3-i3ipc
)

readonly BUILD_PACKAGES=(
    curl
    git
    xz-utils
    gcc
    clang
    pkg-config
    wayland-protocols
    libudev-dev
    libgbm-dev
    libxkbcommon-dev
    libegl1-mesa-dev
    libwayland-dev
    libinput-dev
    libdbus-1-dev
    libsystemd-dev
    libseat-dev
    libpipewire-0.3-dev
    libpango1.0-dev
    libdisplay-info-dev
    libadwaita-1-dev
    libcairo2-dev
    libclang-dev
)

readonly NWG_BUILD_PACKAGES=(
    python3-build
    python3-installer
    python3-setuptools
    python3-wheel
)

export DEBIAN_FRONTEND=noninteractive
export RUSTUP_HOME="/usr/local/rustup"
export CARGO_HOME="/usr/local/cargo"
export PATH="${CARGO_HOME}/bin:${PATH}"

log() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "${BUILD_DIR:-}" ]]; then
        rm -rf "$BUILD_DIR"
    fi
    if [[ -n "${NWG_BUILD_DIR:-}" ]]; then
        rm -rf "$NWG_BUILD_DIR"
    fi
}

trap cleanup EXIT

require_root() {
    [[ "$(id -u)" -eq 0 ]] || die "run this script as root (sudo ./install.sh)"
}

require_arm64() {
    case "$(uname -m)" in
        aarch64|arm64) ;;
        *) die "this installer targets arm64 (Orange Pi Zero 3W); found $(uname -m)" ;;
    esac
}

require_armbian() {
    [[ -r /etc/armbian-release ]] || die "this installer expects an Armbian image (/etc/armbian-release is missing)"
}

warn_platform() {
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "debian" || "${VERSION_CODENAME:-}" != "trixie" ]]; then
        warn "tested with Armbian Debian 13 (trixie); continuing on ${PRETTY_NAME:-unknown}"
    fi

    case "$(uname -r)" in
        *sun60iw2*) ;;
        *) warn "kernel does not look like the Zero 3W vendor kernel: $(uname -r)" ;;
    esac
}

apt_update() {
    apt-get update
}

install_runtime_packages() {
    log "Installing runtime packages"
    apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"
    apt-get clean
}

install_build_packages() {
    log "Installing niri build packages"
    apt-get install -y --no-install-recommends "${BUILD_PACKAGES[@]}"
    apt-get clean
}

enable_user_services() {
    log "Enabling PipeWire user services for all users"
    systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service
}

enable_bluetooth() {
    log "Enabling Bluetooth service"
    systemctl enable --now bluetooth.service || warn "could not enable Bluetooth service"
}

install_rust() {
    if [[ ! -x "${CARGO_HOME}/bin/cargo" ]]; then
        log "Installing Rust (stable)"
        curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable --no-modify-path
    fi

    export PATH="${CARGO_HOME}/bin:${PATH}"

    local version major minor
    version="$(rustc --version | awk '{print $2}')"
    IFS=. read -r major minor _ <<< "$version"
    if (( major < 1 || (major == 1 && minor < 85) )); then
        die "Rust 1.85 or newer is required; found $version"
    fi
}

download() {
    local url="$1"
    local dest="$2"
    curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 -o "$dest" "$url"
}

verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    [[ "$actual" == "$expected" ]] || die "checksum mismatch for $file: expected $expected, got $actual"
}

niri_binary_installed() {
    [[ -x /usr/bin/niri ]] &&
    [[ -f "${STATE_DIR}/niri-${NIRI_VERSION}" ]]
}

niri_files_installed() {
    [[ -x /usr/bin/niri-session ]] &&
    [[ -f /usr/lib/systemd/user/niri.service ]] &&
    [[ -f /usr/lib/systemd/user/niri-shutdown.target ]] &&
    [[ -f /usr/share/wayland-sessions/niri.desktop ]] &&
    [[ -f /usr/share/xdg-desktop-portal/niri-portals.conf ]]
}

install_niri() {
    if niri_binary_installed && niri_files_installed; then
        log "niri ${NIRI_VERSION} is already installed"
        return
    fi

    local need_build=0
    if ! niri_binary_installed; then
        need_build=1
        install_build_packages
        install_rust
    fi

    BUILD_DIR="$(mktemp -d /var/tmp/niri-build.XXXXXX)"
    local source_archive="${BUILD_DIR}/niri-source.tar.gz"
    local vendor_archive="${BUILD_DIR}/niri-vendor.tar.xz"
    local source_dir="${BUILD_DIR}/source"

    log "Downloading niri ${NIRI_VERSION} source"
    download "$NIRI_SOURCE_URL" "$source_archive"
    verify_sha256 "$source_archive" "$NIRI_SOURCE_SHA256"

    mkdir -p "$source_dir"
    tar -xzf "$source_archive" -C "$source_dir" --strip-components=1

    if (( need_build )); then
        log "Downloading niri ${NIRI_VERSION} vendored dependencies"
        download "$NIRI_VENDOR_URL" "$vendor_archive"
        verify_sha256 "$vendor_archive" "$NIRI_VENDOR_SHA256"
        tar -xJf "$vendor_archive" -C "$source_dir"

        mkdir -p "$source_dir/.cargo"
        cat > "$source_dir/.cargo/config.toml" <<EOF
[source.crates-io]
replace-with = "vendored-sources"

[source."git+https://github.com/Smithay/smithay.git?rev=${SMITHAY_REV}"]
git = "https://github.com/Smithay/smithay.git"
rev = "${SMITHAY_REV}"
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF

        log "Building niri ${NIRI_VERSION} (${NIRI_COMMIT:0:12}); this can take a while"
        (
            cd "$source_dir"
            NIRI_BUILD_COMMIT="$NIRI_COMMIT" cargo build --release --frozen -p niri
        )
    fi

    install -d -m 0755 \
        /usr/bin \
        /usr/share/wayland-sessions \
        /usr/share/xdg-desktop-portal \
        /usr/lib/systemd/user

    if (( need_build )); then
        install -m 0755 "$source_dir/target/release/niri" /usr/bin/niri
        printf '%s\n' "$NIRI_COMMIT" > "${STATE_DIR}/niri-${NIRI_VERSION}"
    fi

    install -m 0755 "$source_dir/resources/niri-session" /usr/bin/niri-session
    install -m 0644 "$source_dir/resources/niri.desktop" /usr/share/wayland-sessions/niri.desktop
    install -m 0644 "$source_dir/resources/niri-portals.conf" /usr/share/xdg-desktop-portal/niri-portals.conf
    install -m 0644 "$source_dir/resources/niri.service" /usr/lib/systemd/user/niri.service
    install -m 0644 "$source_dir/resources/niri-shutdown.target" /usr/lib/systemd/user/niri-shutdown.target

    log "Installed niri ${NIRI_VERSION}"
}

find_library() {
    ldconfig -p | awk -v name="$1" '$1 == name { print $NF; exit }'
}

verify_runtime_dependencies() {
    local -A lib_packages=(
        [libEGL.so.1]=libegl1
        [libEGL_mesa.so.0]=libegl-mesa0
        [libxcb-dri2.so.0]=libxcb-dri2-0
        [libwayland-server.so.0]=libwayland-server0
        [libwayland-client.so.0]=libwayland-client0
        [libseat.so.1]=libseat1
        [libdisplay-info.so.2]=libdisplay-info2
        [libgbm.so.1]=libgbm1
        [libinput.so.10]=libinput10
        [libxkbcommon.so.0]=libxkbcommon0
        [libpipewire-0.3.so.0]=libpipewire-0.3-0
        [libpixman-1.so.0]=libpixman-1-0
        [libpango-1.0.so.0]=libpango-1.0-0
        [libcairo.so.2]=libcairo2
        [libglib-2.0.so.0]=libglib2.0-0t64
        [libdbus-1.so.3]=libdbus-1-3
        [libudev.so.1]=libudev1
        [libdrm.so.2]=libdrm2
    )
    local -A missing_packages=()
    local lib path dep
    local missing=0

    log "Verifying niri runtime dependencies"

    for lib in "${!lib_packages[@]}"; do
        path="$(find_library "$lib")"
        if [[ -z "$path" ]]; then
            warn "missing runtime library: $lib (package: ${lib_packages[$lib]})"
            missing_packages["${lib_packages[$lib]}"]=1
            missing=1
            continue
        fi

        while IFS= read -r dep; do
            [[ -n "$dep" ]] || continue
            warn "missing dependency of ${path}: $dep"
            missing=1
        done < <(ldd "$path" 2>/dev/null | awk '/not found/ { print $1 }')
    done

    while IFS= read -r dep; do
        [[ -n "$dep" ]] || continue
        warn "missing dependency of /usr/bin/niri: $dep"
        missing=1
    done < <(ldd /usr/bin/niri 2>/dev/null | awk '/not found/ { print $1 }')

    if (( missing )); then
        if ((${#missing_packages[@]})); then
            warn "install these packages: ${!missing_packages[*]}"
        fi
        die "runtime dependency check failed"
    fi

    log "Runtime dependency check passed"
}

nwg_displays_installed() {
    [[ -x /usr/local/bin/nwg-displays ]] &&
    [[ -f "${STATE_DIR}/nwg-displays-${NWG_DISPLAYS_VERSION}" ]]
}

install_nwg_displays() {
    if nwg_displays_installed; then
        log "nwg-displays ${NWG_DISPLAYS_VERSION} is already installed"
        return
    fi

    log "Installing nwg-displays build packages"
    apt-get install -y --no-install-recommends "${NWG_BUILD_PACKAGES[@]}"
    apt-get clean

    NWG_BUILD_DIR="$(mktemp -d /var/tmp/nwg-displays-build.XXXXXX)"
    local source_archive="${NWG_BUILD_DIR}/nwg-displays.tar.gz"
    local source_dir="${NWG_BUILD_DIR}/source"

    log "Downloading nwg-displays ${NWG_DISPLAYS_VERSION}"
    download "$NWG_DISPLAYS_URL" "$source_archive"
    verify_sha256 "$source_archive" "$NWG_DISPLAYS_SHA256"

    mkdir -p "$source_dir"
    tar -xzf "$source_archive" -C "$source_dir" --strip-components=1

    log "Building nwg-displays ${NWG_DISPLAYS_VERSION}"
    (
        cd "$source_dir"
        python3 -m build --wheel --no-isolation
    )

    log "Installing nwg-displays ${NWG_DISPLAYS_VERSION} to /usr/local"
    python3 -m installer --prefix=/usr/local "$source_dir"/dist/*.whl
    install -D -m 0644 "$source_dir/nwg-displays.desktop" /usr/local/share/applications/nwg-displays.desktop
    install -D -m 0644 "$source_dir/nwg-displays.svg" /usr/local/share/pixmaps/nwg-displays.svg
    install -D -m 0644 "$source_dir/LICENSE" /usr/local/share/licenses/nwg-displays/LICENSE
    install -D -m 0644 "$source_dir/README.md" /usr/local/share/doc/nwg-displays/README.md

    [[ -x /usr/local/bin/nwg-displays ]] || die "nwg-displays installation failed"

    printf '%s\n' "$NWG_DISPLAYS_VERSION" > "${STATE_DIR}/nwg-displays-${NWG_DISPLAYS_VERSION}"
    log "Installed nwg-displays ${NWG_DISPLAYS_VERSION}"
}

validate_config() {
    log "Validating the niri configuration"
    /usr/bin/niri validate --config "${SCRIPT_DIR}/config/niri/config.kdl"
}

copy_config() {
    local src="$1"
    local dest="$2"
    local owner="${3:-root}"
    local group="${4:-root}"
    local mode="${5:-0644}"
    install -D -m "$mode" -o "$owner" -g "$group" "$src" "$dest"
}

copy_config_if_missing() {
    local src="$1"
    local dest="$2"
    local owner="${3:-root}"
    local group="${4:-root}"
    local mode="${5:-0644}"

    if [[ -e "$dest" ]]; then
        return 0
    fi

    copy_config "$src" "$dest" "$owner" "$group" "$mode"
}

detect_target_user() {
    local user="${SUDO_USER:-}"
    if [[ -z "$user" || "$user" == "root" ]]; then
        user="$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)"
    fi
    [[ -n "$user" ]] || return 1
    printf '%s\n' "$user"
}

install_configs() {
    log "Installing desktop configuration"

    copy_config "${SCRIPT_DIR}/config/niri/config.kdl" /etc/skel/.config/niri/config.kdl
    copy_config_if_missing "${SCRIPT_DIR}/config/niri/monitor.kdl" /etc/skel/.config/niri/monitor.kdl
    copy_config "${SCRIPT_DIR}/config/foot/foot.ini" /etc/skel/.config/foot/foot.ini
    copy_config "${SCRIPT_DIR}/config/fuzzel/fuzzel.ini" /etc/skel/.config/fuzzel/fuzzel.ini
    copy_config "${SCRIPT_DIR}/config/gtk-3.0/settings.ini" /etc/skel/.config/gtk-3.0/settings.ini
    copy_config "${SCRIPT_DIR}/config/gtk-4.0/settings.ini" /etc/skel/.config/gtk-4.0/settings.ini

    if [[ -n "${TARGET_USER}" && -n "${TARGET_HOME}" && -d "${TARGET_HOME}" ]]; then
        local dir
        install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "${TARGET_HOME}/.config"
        for dir in niri foot fuzzel gtk-3.0 gtk-4.0; do
            install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "${TARGET_HOME}/.config/${dir}"
        done

        copy_config "${SCRIPT_DIR}/config/niri/config.kdl" "${TARGET_HOME}/.config/niri/config.kdl" "$TARGET_USER" "$TARGET_GROUP"
        copy_config_if_missing "${SCRIPT_DIR}/config/niri/monitor.kdl" "${TARGET_HOME}/.config/niri/monitor.kdl" "$TARGET_USER" "$TARGET_GROUP"
        copy_config "${SCRIPT_DIR}/config/foot/foot.ini" "${TARGET_HOME}/.config/foot/foot.ini" "$TARGET_USER" "$TARGET_GROUP"
        copy_config "${SCRIPT_DIR}/config/fuzzel/fuzzel.ini" "${TARGET_HOME}/.config/fuzzel/fuzzel.ini" "$TARGET_USER" "$TARGET_GROUP"
        copy_config "${SCRIPT_DIR}/config/gtk-3.0/settings.ini" "${TARGET_HOME}/.config/gtk-3.0/settings.ini" "$TARGET_USER" "$TARGET_GROUP"
        copy_config "${SCRIPT_DIR}/config/gtk-4.0/settings.ini" "${TARGET_HOME}/.config/gtk-4.0/settings.ini" "$TARGET_USER" "$TARGET_GROUP"

        install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "${TARGET_HOME}/Pictures"
        install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "${TARGET_HOME}/Pictures/Screenshots"
    else
        warn "no regular user found; only /etc/skel was populated"
    fi
}

main() {
    require_root
    require_arm64
    require_armbian
    warn_platform

    install -d -m 0755 "$STATE_DIR"

    TARGET_USER="$(detect_target_user || true)"
    if [[ -n "${TARGET_USER}" ]]; then
        TARGET_HOME="$(getent passwd "$TARGET_USER" | awk -F: '{print $6}')"
        TARGET_GROUP="$(id -gn "$TARGET_USER")"
    else
        TARGET_HOME=""
        TARGET_GROUP=""
    fi

    apt_update
    install_runtime_packages
    enable_user_services
    enable_bluetooth
    install_niri
    install_nwg_displays
    verify_runtime_dependencies
    validate_config
    install_configs

    log "Done"
    log "Network configuration was left untouched."
    log "Connect the USB-C monitor before rebooting, then log in on tty1."
    log "Start niri manually with: niri"
    log "Use Super+T for foot and Super+D for fuzzel."
    log "Run nwg-displays from fuzzel to arrange monitors."
}

main "$@"
