# Installing Paddlefish OS

Paddlefish OS variants (desktop, laptop, server) are installed with the
bootc-native installer from **any running Linux with podman** - for example a
stock Fedora KDE/Workstation live USB. There is no Paddlefish-branded
installer media to build or maintain.

## Before you start

- A container registry hosting the image to install
  (e.g. `ghcr.io/<owner>/paddlefish-os-desktop:latest`). The helper defaults to
  `ghcr.io/luuka5`; set `PADDLEFISH_REGISTRY` if yours differs.
- Boot media for any Fedora-family live environment (or any Linux with podman).
- A network connection so the live session can fetch the image from the
  registry. If the image is private, log in first: `sudo podman login ghcr.io`.
- A freshly installed system ships the default user `user` with password
  `paddlefish` and **forces a password change on its first real boot**
  (`user-password-setup.service`). This is intentional.

## Procedure (whole disk)

1. Boot the stock Fedora live media. Open a terminal.
2. Ensure podman is present:

       sudo dnf install -y podman

3. Run the installer helper (from this repo, or copy it to the live session):

       sudo ./install-to-disk.sh desktop      # or: laptop | server

   Or use `PADDLEFISH_REGISTRY=ghcr.io/<owner> sudo ./install-to-disk.sh desktop`
   to target a different registry.

4. Read the disk list, type the target whole disk (e.g. `/dev/nvme0n1`), and
   confirm the wipe by typing `YES` when prompted.
5. Reboot when it finishes.
6. On first boot you will be asked to set a new password for `user`. You are in
   the `wheel` group, so `sudo` works with that password.

The one-liner, if you prefer not to copy the script:

    sudo podman run --rm --privileged --pid=host --ipc=host \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev --security-opt label=type:unconfined_t \
        ghcr.io/<owner>/paddlefish-os-desktop:latest \
        bootc install to-disk --wipe \
        --target-imgref ghcr.io/<owner>/paddlefish-os-desktop:latest /dev/nvme0n1

## Notes

- The whole-disk path erases the entire selected disk. Never point it at a disk
  holding data you need.
- After install, the system tracks the image it was installed from; update with:

       sudo bootc upgrade

- The images ship no separate installer tooling; `install-to-disk.sh` is the
  reference helper and lives in this repository.

## Server images in place

The server variant can also be deployed in place on an existing Fedora-family
system with `deploy/install-server.sh` (no live boot needed).
