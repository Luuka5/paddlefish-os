ARG FEDORA_MAJOR_VERSION=44
ARG AKMODS_NVIDIA_IMAGE=ghcr.io/ublue-os/akmods-nvidia-open:main-${FEDORA_MAJOR_VERSION}
ARG BASE_IMAGE=ghcr.io/ublue-os/base-main:latest
ARG IMAGE_NAME=desktop
ARG BUILD_NVIDIA=N
ARG BUILD_DESKTOP=Y

FROM ${AKMODS_NVIDIA_IMAGE} AS akmods_nvidia

FROM ${BASE_IMAGE}

COPY system_files/all/ /
COPY system_files/${IMAGE_NAME}/ /
COPY scripts/ /tmp/scripts/

RUN /tmp/scripts/base.sh

RUN if [ "${BUILD_DESKTOP}" = "Y" ]; then /tmp/scripts/niri.sh; fi

RUN --mount=type=bind,from=akmods_nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    if [ "${BUILD_NVIDIA}" = "Y" ]; then /tmp/scripts/nvidia-repo.sh; fi

RUN --mount=type=bind,from=akmods_nvidia,src=/rpms,dst=/tmp/akmods-nv-rpms \
    if [ "${BUILD_NVIDIA}" = "Y" ]; then /tmp/scripts/nvidia.sh; fi

RUN rm -rf /tmp/scripts /run/dnf /var/log/dnf5.log \
         /var/cache/libdnf5 /var/lib/dnf/repos /var/cache/ldconfig/aux-cache

RUN bootc container lint
