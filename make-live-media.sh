#!/bin/sh
set -eu

# Produce a Paddlefish install live ISO from an official Fedora live spin.
# Adds the whole repo and podman-saved copies of the built OS images onto the
# ISO root so an install needs no network configuration in the live session.
#
# Produce ISO only (no USB writing). Defaults to the Fedora 44 Xfce spin to
# match FEDORA_MAJOR_VERSION; override with --flavor / --fedora / --iso.
#
# No external tools are needed on the host: xorriso runs inside a throwaway
# Fedora container. Only podman, curl and the built images are required.
#
# Usage:
#   ./make-live-media.sh                     # download Fedora Xfce 44, embed all 3 images
#   ./make-live-media.sh --iso fedora.iso    # use an existing ISO
#   PADDLEFISH_IMAGES="desktop" ./make-live-media.sh --iso fedora.iso

FLAVOR="${FLAVOR:-xfce}"
FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"
XORRISO_IMAGE="${XORRISO_IMAGE:-registry.fedoraproject.org/fedora:${FEDORA_MAJOR_VERSION}}"
VARIANTS="${PADDLEFISH_IMAGES:-desktop laptop server}"
BASE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_MAJOR_VERSION}/Spins/x86_64/iso"
INPUT_ISO=""
OUT_DIR="${OUTPUT_DIR:-./output}"
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT HUP INT TERM

while [ $# -gt 0 ]; do
    case "$1" in
        --iso) INPUT_ISO="$2"; shift 2 ;;
        *) echo "Unknown argument: $1 (only --iso is supported)" >&2; exit 1 ;;
    esac
done

command -v podman >/dev/null 2>&1 || {
    echo "Error: podman is required" >&2
    exit 1
}

# --- Verify the images to embed exist -------------------------------
for v in ${VARIANTS}; do
    if ! podman image exists "localhost/paddlefish-os-${v}:latest"; then
        echo "Error: localhost/paddlefish-os-${v}:latest not found. Build it first with: ./build.sh ${v}" >&2
        exit 1
    fi
done

# --- Obtain the base Fedora live ISO ---------------------------------
if [ -n "${INPUT_ISO}" ]; then
    [ -f "${INPUT_ISO}" ] || { echo "Error: ${INPUT_ISO} not found" >&2; exit 1; }
    ISO_FILE="$(realpath "${INPUT_ISO}")"
else
    mkdir -p "${OUT_DIR}"
    LATEST_ISO="$(curl -fsSL -A 'Mozilla/5.0' "${BASE_URL}/" \
        | grep -oiE "Fedora-${FLAVOR}-Live-${FEDORA_MAJOR_VERSION}-[0-9.]+\.x86_64\.iso" \
        | sort -uV | tail -n1 || true)"
    [ -n "${LATEST_ISO}" ] || { echo "Error: could not locate Fedora ${FLAVOR} ${FEDORA_MAJOR_VERSION} live ISO on ${BASE_URL}" >&2; exit 1; }
    ISO_FILE="${OUT_DIR}/${LATEST_ISO}"
    if [ ! -f "${ISO_FILE}" ]; then
        echo "Downloading ${BASE_URL}/${LATEST_ISO} ..."
        curl -fL --retry 3 -o "${ISO_FILE}" "${BASE_URL}/${LATEST_ISO}"
    else
        echo "Using cached ${ISO_FILE}"
    fi
fi

# --- Stage content ----------------------------------------------------
mkdir -p "${STAGE}/paddlefish/images"

# Whole repo (excluding build artifacts and VCS dirs).
cp -a ./build.sh ./Containerfile ./scripts ./system_files ./deploy \
      ./install-to-disk.sh ./foot.ini ./media "${STAGE}/paddlefish/"

# Built OS images as podman save tars.
for v in ${VARIANTS}; do
    echo "Saving localhost/paddlefish-os-${v}:latest ..."
    podman save -o "${STAGE}/paddlefish/images/paddlefish-os-${v}.tar" \
        "localhost/paddlefish-os-${v}:latest"
done

# --- Remaster the ISO (xorriso inside a container) -------------------
mkdir -p "${OUT_DIR}"
OUT_ISO="${OUT_DIR}/paddlefish-live-${FLAVOR}-${FEDORA_MAJOR_VERSION}.iso"
OUT_ISO_ABS="$(realpath "${OUT_ISO}" 2>/dev/null || printf '%s' "${PWD}/${OUT_ISO}")"
mkdir -p "$(dirname "${OUT_ISO_ABS}")"

echo "Remastering ${ISO_FILE} -> ${OUT_ISO_ABS}"
echo "Running xorriso in container ${XORRISO_IMAGE} ..."

# Rootless podman maps the container's root to the invoking user, so the ISO
# written into the bind-mounted output dir is owned by us on the host.
podman run --rm \
    --security-opt label=disable \
    -v "${STAGE}:/stage:rw" \
    -v "$(dirname "${OUT_ISO_ABS}"):/out:rw" \
    -v "${ISO_FILE}:/input.iso:ro" \
    "${XORRISO_IMAGE}" \
    sh -c 'dnf -y install xorriso >/dev/null && \
        xorriso -indev /input.iso \
            -outdev "/out/$(basename "$1")" \
            -map /stage/paddlefish /paddlefish \
            -map /stage/paddlefish/media/INSTALL.txt /INSTALL.txt \
            -boot_image any replay \
            -commit -eject all' sh "${OUT_ISO_ABS}"

echo
echo "ISO built: ${OUT_ISO_ABS}"
echo "Boot it, open a terminal, then:"
echo "  cd /paddlefish"
echo "  sudo ./install-to-disk.sh desktop    # or: laptop | server"
echo "No network is needed during install; the OS images are bundled."
