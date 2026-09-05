# Paddlefish OS

Clean, immutable bootc container images for a personal OS. The repo only
builds container images; it ships no installer or install media.

## Images

| Variant | Base | Contents |
|---------|------|----------|
| `desktop` | `ghcr.io/ublue-os/base-main:latest` | niri + foot + waybar + swaylock + firefox, NVIDIA drivers |
| `laptop` | `ghcr.io/ublue-os/base-main:latest` | niri + foot + waybar + swaylock + firefox (no NVIDIA) |
| `server` | `quay.io/fedora/fedora-bootc:44` | headless, minimal tools |

## Build

```sh
./scripts/build.sh desktop        # or: laptop | server | all
```

Produces `localhost/paddlefish-os-<variant>:latest`.

## Install / switch

There is no installer here. Install any Fedora bootc-based system with its
official installer (creating your own user account), then:

```sh
sudo bootc switch ghcr.io/<owner>/paddlefish-os-<variant>:latest
```

`bootc switch` preserves `/etc` and `/var`, so the user account you created and
its home directory survive. The images bake **no** default user; create your
own during install.

## User config

Default user configuration ships in `/etc/skel` and is applied when a new
account is created:

- fish (shell defaults, prompt, theme)
- foot (terminal)
- niri (compositor)
- nvim (placeholder)

`/etc/skel` is used by `useradd`, so accounts created **after** switching get
the defaults automatically. If your account predates the switch, apply them to
your existing home once:

```sh
cp -r /etc/skel/. ~/
```

New accounts default to the fish shell.
