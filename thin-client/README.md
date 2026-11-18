# Paddlefish thin client

An isolated experiment for turning an Orange Pi Zero 3W into a thin client:
Armbian boots to a minimal CLI login, niri is started manually, and the real
development work happens over SSH on a separate host running the published
Paddlefish dev images.

## Isolation contract

Do not modify, import, source, symlink, copy from, or otherwise reuse anything
from the rest of this repository — including `Containerfile`,
`Containerfile.dev`, `scripts/`, `system_files/`, the root `README.md`,
`.github/`, or any other branch — without explicit user approval.

This directory is a separate experiment. All Paddlefish OS configuration here
is a copy, not a reference. Upstream changes must be manually copied into this
folder and reviewed again. `COPIED.md` records the source commit and whether
each file is verbatim, pruned, or adapted. The copies listed there are the only
permitted lineage from the main branch.

This bookmark is rooted at an empty commit and shares no files or history with
`main`. Do not merge, cherry-pick, or push it to a long-lived branch without
explicit approval. Nothing here is built by the main repository's CI.

## Target hardware

- Orange Pi Zero 3W, 12 GB LPDDR5 variant
- Allwinner A733 (`sun60iw2`), 2× Cortex-A76 + 6× Cortex-A55
- Wi-Fi 6 and Bluetooth 5.4; no Ethernet and no USB-A ports
- One mini HDMI 2.0 output
- One USB-C 3.1 Gen 2 OTG port with DisplayPort Alt Mode
- One separate USB-C power-only port, 5 V/3 A, no USB-PD

Use a USB-C hub or a Bluetooth keyboard and mouse. The board cannot be powered
from the monitor's USB-C port.

## Image and USB-C display

Use **Armbian 26.8.x Rolling Release, Debian 13 (trixie), Minimal/IOT CLI,
vendor kernel 6.6.98**.

All published Zero 3W images are minimal CLI images with the vendor kernel;
there is no mainline-kernel or desktop image for this board. Debian is preferred
over Ubuntu here because Debian's Firefox ESR is a real `.deb`, while Ubuntu
26.04's `firefox` is a snap transitional package.

USB-C display notes:

- Native USB-C DisplayPort monitors use the 4-lane DP-only mode
  (`TYPEC_DP_STATE_C`). The vendor kernel generally handles this.
- USB-C DP+USB adapters, docks, and touch monitors use 2-lane DP and need
  Armbian PR #11211 (merged 2026-11-04). Stable 26.8.1 and 26.8.3 predate that
  fix; the current rolling image is built after it.
- Vendor issue #136, where HPD can be reported before the PHY enters DP mode,
  is still open upstream. Connect the monitor **before** booting the board.
- Mini HDMI is the fallback output for debugging.
- Use a separate 5 V/3 A supply for the board's power-only USB-C port.

## Flash and first boot

1. Flash the Armbian Minimal CLI image for the Orange Pi Zero 3W.
2. Boot with the USB-C monitor already connected.
3. Log in on tty1 and connect Wi-Fi with `sudo nmtui`.
4. Copy this directory to the board, for example:
   `scp -r thin-client user@thin-client.local:~/`
5. Run the installer locally on tty1:
   `cd ~/thin-client && sudo ./install.sh`
6. Reboot, connect the monitor before power, and log in on tty1 again.
7. Start niri manually with `niri`.

The first run downloads and builds niri on the board. Expect roughly 15–40
minutes depending on storage and network speed, and keep several GB free.
Running the installer again is safe and skips the niri build if it already
succeeded.

The installer does not edit Netplan, reconfigure `systemd-networkd`, or invoke
`systemctl` for NetworkManager. Existing network configuration is left alone.

## What the installer does

- Installs a minimal Wayland desktop package set: `foot`, `fuzzel`,
  `firefox-esr`, PipeWire/WirePlumber, `pavucontrol`, NetworkManager, fonts,
  portals, OpenSSH client, and the Mesa/XCB runtime libraries niri loads.
- Installs `wpasupplicant` explicitly because the installer does not pull
  package recommendations.
- Keeps NetworkManager available for `nmtui` and `nmcli`, but does not invoke
  `systemctl` or Netplan to start, enable, disable, or reconfigure networking.
- Builds niri v26.04 from pinned source and pinned vendored dependencies,
  verifying both SHA-256 checksums. The build embeds the pinned commit.
- Verifies niri's runtime libraries with `ldconfig` and `ldd` after installation,
  and reports the Debian package that provides any missing library.
- Installs niri directly from the built artifacts, without `cargo-deb` and
  without pulling the unused `alacritty` dependency declared in niri's Debian
  metadata.
- Installs the copied niri, foot, fuzzel, and GTK configuration into
  `/etc/skel` and the current human user's home directory.
- Enables the PipeWire, PipeWire-Pulse, and WirePlumber user units globally.
- Creates `~/Pictures/Screenshots` for the screenshot bind.

There is no greetd, no autologin, no display manager, no auto-launch hook, no
Waybar, no notification daemon, no screen locker, no Fish configuration, and no
Neovim configuration. Login stays manual on tty1; run `niri` when ready.

## Using the session

After login on tty1, start niri manually:

```sh
niri
```

Use `niri-session` instead if you want niri to run through the installed systemd
user units.

- `Super+T` or `Super+Return`: open foot
- `Super+D` or `Super+Space`: open fuzzel
- `Super+E`: open Firefox
- `Mod+Shift+/`: show the niri hotkey overlay

Wi-Fi and other network setup: run `nmtui` inside foot. Pair a Bluetooth
keyboard or mouse with `bluetoothctl` inside foot. Audio: run `pavucontrol`, or
use the volume keys managed by WirePlumber.

The copied niri configuration keeps the Paddlefish/Srcery colors, window and
workspace navigation, screenshots, Firefox picture-in-picture rules, and volume
keys. Waybar, Bluetooth helper scripts, swaylock, mako, orca, `playerctl`, and
`brightnessctl` bindings were removed because those programs are not installed.

## Development environment over SSH

The dev containers do not run sshd and are not meant to. Use an existing remote
host that already runs sshd and pulls the published images
`ghcr.io/<owner>/paddlefish-dev-{core,gui,nvidia}:latest`.

```sh
ssh -t user@devhost
cd /path/to/project
paddlefish-dev
```

`paddlefish-dev` starts a login shell in the project container. The `--gui`
and `--gpu` options are for a local host sharing its display or GPU, not for
this SSH-only thin-client workflow.

If you want the Paseo web UI in the thin client's Firefox, start the container
with a localhost-only published port and forward it over SSH:

```sh
ssh -L 6767:localhost:6767 user@devhost
# on devhost:
cd /path/to/project
paddlefish-dev -p 127.0.0.1:6767:6767
# start the Paseo daemon in the container, then open:
# http://localhost:6767
```

## Troubleshooting

USB-C display not detected:

```sh
dmesg | grep -Ei 'typec|edp|dp'
for f in /sys/class/drm/card*-*/status; do printf '%s: ' "$f"; cat "$f"; done
niri msg outputs
```

Connect the monitor before powering the board, confirm the board has its own
5 V/3 A supply, and try mini HDMI to separate a display problem from a DP
problem.

niri did not start after login:

```sh
tty
id -u
niri --version
niri validate --config ~/.config/niri/config.kdl
journalctl --user -u niri -b
ldd /usr/lib/aarch64-linux-gnu/libEGL_mesa.so.0 | grep 'not found'
ldd /usr/bin/niri | grep 'not found'
```

If niri panics while loading LibEGL with `libxcb-dri2.so.0`, install the missing
provider:

```sh
sudo apt-get install libxcb-dri2-0
```

The same pattern applies to any other `not found` line. `dpkg -S` finds the
provider for installed files; Debian package search finds it for missing ones.

Run `niri` from a text console as the regular user. Do not use `su` to start it,
because the user session and environment may be incomplete. X11 applications
are not supported because XWayland is not installed.

No audio:

```sh
systemctl --user status pipewire pipewire-pulse wireplumber
wpctl status
pavucontrol
```

Firefox does not open from the `Super+E` bind: check `command -v firefox`.
Debian's `firefox-esr` package provides the `/usr/bin/firefox` wrapper.

## Uninstall

The uninstall script removes installed files by default. It keeps packages and
user configuration unless asked otherwise.

```sh
sudo ./uninstall.sh --dry-run
sudo ./uninstall.sh
sudo ./uninstall.sh --purge-configs
sudo ./uninstall.sh --clean-temp
sudo ./uninstall.sh --list-packages
```

`--purge-configs` removes the copied niri, foot, fuzzel, and GTK configuration
from `/etc/skel` and the selected user's home. `--list-packages` only prints
review hints; package removal is intentionally manual.

## Maintaining the copies

When Paddlefish main changes a copied file, manually bring the change here,
re-run `niri validate`, and update `COPIED.md`. Do not add includes, symlinks,
runtime path references, or build steps that reach into the main branch.
