# Paddlefish OS

Clean, immutable bootc container images for a personal OS. The repo only
builds container images; it ships no installer or install media.

## Images

| Variant | Base | Notes |
|---------|------|-------|
| `desktop` | `ghcr.io/ublue-os/base-main:latest` | graphical desktop (no NVIDIA) |
| `desktop-nvidia` | `ghcr.io/ublue-os/base-main:latest` | graphical desktop, NVIDIA drivers |
| `server` | `quay.io/fedora/fedora-bootc:44` | headless, minimal tools |

## Build

```sh
./scripts/build.sh desktop        # or: desktop-nvidia | server | all
```

Produces `localhost/paddlefish-os-<variant>:latest`. Push it to a registry to
install it.

## Install

The images bake **no** default user; create your own account. There are two
ways to install.

### Fresh install (`bootc install`)

From any Linux environment with podman (for example a Fedora live USB), install
onto a whole disk:

```sh
sudo podman run --rm --privileged --pid=host --ipc=host \
    -v /var/lib/containers:/var/lib/containers \
    -v /dev:/dev \
    ghcr.io/luuka5/paddlefish-os-<variant>:latest \
    bootc install to-disk --wipe \
    --target-imgref ghcr.io/luuka5/paddlefish-os-<variant>:latest /dev/sdX
```

`/dev/sdX` is erased and replaced. On the new system, log in and create your
user account.

### Switch an existing bootc system (`bootc switch`)

Install any Fedora bootc-based system with its official installer, creating
your user account, then:

```sh
sudo bootc switch ghcr.io/luuka5/paddlefish-os-<variant>:latest
```

`bootc switch` preserves `/etc` and `/var`, so the user account and its home
directory survive the switch.

After install, the system tracks the image it was installed from or switched
to; update it with `sudo bootc upgrade`.

## User config

Default user configuration ships in `/etc/skel` (shell, terminal, compositor,
editor defaults) and is applied when a new account is created. Accounts created
**after** installing get the defaults automatically. If your account already
exists, apply them to your home once:

```sh
cp -r /etc/skel/. ~/
```

New accounts use the shell configured as the image default.

## Desktop

The desktop variants ship PipeWire (audio, `pavucontrol`) plus the gnome
portal backend, so screen sharing and portal-based screenshots work out of the
box. If your account predates this setup, run `systemctl --user preset-all`
once to enable the PipeWire user units.
