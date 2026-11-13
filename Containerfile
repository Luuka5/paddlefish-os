ARG FEDORA_MAJOR_VERSION=45
ARG AKMODS_NVIDIA_IMAGE=ghcr.io/ublue-os/akmods-nvidia-open:main-${FEDORA_MAJOR_VERSION}
ARG BASE_IMAGE=ghcr.io/ublue-os/base-main:latest
ARG IMAGE_NAME=desktop
ARG BUILD_NVIDIA=N
ARG BUILD_DESKTOP=Y

FROM ${AKMODS_NVIDIA_IMAGE} AS akmods_nvidia

FROM ${BASE_IMAGE} AS shikane_builder

RUN dnf5 install -y cargo && \
    CARGO_HOME=/tmp/cargo cargo install --locked --root /out shikane && \
    rm -rf /tmp/cargo /var/cache/dnf /var/cache/libdnf5

FROM ${BASE_IMAGE}

# Re-declare so these are available inside RUN instructions of this stage.
ARG IMAGE_NAME=desktop
ARG BUILD_DESKTOP=Y
ARG BUILD_NVIDIA=N

# Fail loudly (instead of silently skipping a feature) if a gate is unset or
# invalid. Without this, a missing gate variable would quietly produce an image
# missing desktop steps and the build would still "succeed".
RUN \
    case "${BUILD_DESKTOP}" in Y|N) ;; *) echo "BUILD_DESKTOP must be Y or N (got '${BUILD_DESKTOP}')" >&2; exit 1;; esac && \
    case "${BUILD_NVIDIA}" in Y|N) ;; *) echo "BUILD_NVIDIA must be Y or N (got '${BUILD_NVIDIA}')" >&2; exit 1;; esac

COPY system_files/all/ /
COPY scripts/base.sh /tmp/scripts/base.sh

# Runs before the variant overlay so this (heavy) layer is shared and cached
# once across all variants.
RUN /tmp/scripts/base.sh

COPY system_files/${IMAGE_NAME}/ /
COPY scripts/ /tmp/scripts/
COPY --from=shikane_builder /out/bin/shikane /usr/local/bin/shikane
COPY --from=shikane_builder /out/bin/shikanectl /usr/local/bin/shikanectl

# User presets are policy, not enablement: apply Shikane's target link at
# image build time so it works for users created by installers as well as
# users created by first boot.
RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then \
        install -d /etc/systemd/user/graphical-session.target.wants && \
        ln -s /usr/lib/systemd/user/shikane.service \
            /etc/systemd/user/graphical-session.target.wants/shikane.service; \
    fi

RUN /tmp/scripts/nvim-plugins.sh

RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then /tmp/scripts/niri.sh; fi

RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then /tmp/scripts/gui-apps.sh; fi

RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then /tmp/scripts/flatpak-apps.sh; fi

RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then /tmp/scripts/power.sh; fi

RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then glib-compile-schemas /usr/share/glib-2.0/schemas; fi

RUN --mount=type=bind,from=akmods_nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    if [ "${BUILD_NVIDIA}" = "Y" ]; then /tmp/scripts/nvidia-repo.sh; fi

RUN --mount=type=bind,from=akmods_nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    if [ "${BUILD_NVIDIA}" = "Y" ]; then /tmp/scripts/nvidia.sh; fi

RUN rm -rf /tmp/scripts /tmp/nvim.root /run/dnf /var/log/dnf5.log \
         /var/cache/libdnf5 /var/lib/dnf/repos /var/cache/ldconfig/aux-cache

RUN bootc container lint
