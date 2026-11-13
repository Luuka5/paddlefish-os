#!/bin/sh
set -euo pipefail

# NVIDIA CUDA Toolkit for the nvidia variant. The GPU device and driver
# libraries are injected at runtime from the host via CDI (--device
# nvidia.com/gpu=all); this only adds the toolkit (nvcc, cudart, cu* libraries)
# so CUDA code and runtime-compiled kernels (e.g. Cycles) can be built.
#
# FEDORA_MAJOR_VERSION is passed in from the build so the repo matches the base
# image; the authoritative NVIDIA .repo file is fetched for that major.
FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-45}"
cuda_repo="https://developer.download.nvidia.com/compute/cuda/repos/fedora${FEDORA_MAJOR_VERSION}/x86_64"

# Fetch NVIDIA's own repo file for this Fedora major instead of hardcoding it
# (it carries the correct baseurl and gpgkey). No dnf plugins required.
curl -fsSL -o /etc/yum.repos.d/cuda-fedora.repo \
    "${cuda_repo}/cuda-fedora${FEDORA_MAJOR_VERSION}.repo"

# Toolkit only. Installing the `cuda` meta instead would also pull the driver
# bundle, which must come from the host. NVIDIA no longer publishes the
# unversioned package name for every Fedora release, so resolve the latest
# versioned toolkit package when the alias is unavailable.
if ! dnf5 install -y cuda-toolkit; then
    cuda_toolkit="$(dnf5 repoquery --available --latest-limit=1 \
        --qf '%{name}' 'cuda-toolkit-[0-9]*' | sed -n '1p')"
    if [ -z "${cuda_toolkit}" ]; then
        echo "No versioned CUDA toolkit package is available" >&2
        exit 1
    fi
    dnf5 install -y "${cuda_toolkit}"
fi

dnf5 clean all

# Make the toolkit available to all users.
printf 'export PATH=/usr/local/cuda/bin:$PATH\n' > /etc/profile.d/cuda.sh
printf 'set -gx PATH /usr/local/cuda/bin $PATH\n' > /etc/fish/conf.d/cuda.fish
printf '/usr/local/cuda/lib64\n' > /etc/ld.so.conf.d/cuda.conf
ldconfig

rm -rf /run/dnf /var/log/dnf5.log /var/cache/libdnf5