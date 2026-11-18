# Copied configuration provenance

Paddlefish source: `main` at `6a9f6cd7` ("Add ps"), copied on 2026-11-17.

These files are manual copies. They are not included, sourced, symlinked, or
read from the main branch at runtime. Any future upstream change must be copied
and reviewed here, then recorded in this file.

## Copied from Paddlefish

| Destination | Source | Status | Notes |
| --- | --- | --- | --- |
| `config/niri/config.kdl` | `system_files/all/etc/skel/.config/niri/config.kdl` | Adapted | Removed Waybar/nm-applet startup, Waybar toggle, Bluetooth helper binds, swaylock, mako, orca, `playerctl`, and `brightnessctl` binds. Kept Srcery colors, navigation/workspace/layout binds, screenshots, Firefox PiP rule, and `wpctl` volume keys. Added the top-level `include "monitor.kdl"` for nwg-displays output configuration. |
| `config/foot/foot.ini` | `system_files/all/etc/skel/.config/foot/foot.ini` | Adapted | Changed `font=FiraCode Nerd Font Mono:size=9` to `font=FiraCode:size=9`. Colors and OSC 52 copy-only setting unchanged. |
| `config/fuzzel/fuzzel.ini` | `system_files/all/etc/skel/.config/fuzzel/fuzzel.ini` | Adapted | Changed `font=FiraCode Nerd Font Mono:size=12` to `font=FiraCode:size=12`. Colors and layout unchanged. |
| `config/gtk-3.0/settings.ini` | `system_files/all/etc/skel/.config/gtk-3.0/settings.ini` | Verbatim | Dark theme and Adwaita icon theme. |
| `config/gtk-4.0/settings.ini` | `system_files/all/etc/skel/.config/gtk-4.0/settings.ini` | Verbatim | Dark theme preference. |

## Authored for this branch

| File | Purpose |
| --- | --- |
| `README.md` | Standalone build and usage instructions, including the isolation contract. |
| `install.sh` | Idempotent installer for the Armbian image and Orange Pi Zero 3W, including pinned niri and nwg-displays source builds. |
| `uninstall.sh` | File-only uninstaller with opt-in config purge and temp cleanup. |
| `config/niri/monitor.kdl` | Empty placeholder for nwg-displays output configuration; preserved across reinstalls. |
| `COPIED.md` | This provenance record. |

## Pinned runtime sources

These sources are downloaded, checksum-verified, built, and installed by
`install.sh`; they are not imported into the repository.

| Component | Version | Source | SHA-256 |
| --- | --- | --- | --- |
| niri | `26.04` (`8ed0da44d974c32c6877d2f4630c314da0717ecb`) | `https://github.com/niri-wm/niri/archive/refs/tags/v26.04.tar.gz` | `134c602d8e0d53413a52d6cd58f9ce7e79a07d03288ee0a51ba1abd5db1b1ad9` |
| niri vendored dependencies | `26.04` | `https://github.com/niri-wm/niri/releases/download/v26.04/niri-26.04-vendored-dependencies.tar.xz` | `407c525cd78710e72455c48741756857ca47dc32910a42f82cd40992a34beed6` |
| nwg-displays | `0.5.0` | `https://github.com/nwg-piotr/nwg-displays/archive/refs/tags/v0.5.0.tar.gz` | `28dfe825e7a6a18df62d36aa1b6b7d232ab86b7f06f99994ad00c04e8b4ccfbc` |

## Review checklist for future copies

1. Copy the upstream file into `thin-client/`; never reference it in place.
2. Re-apply the modifications listed above.
3. Run `niri validate --config config/niri/config.kdl`.
4. Update the source commit and notes in this file.
5. Keep the main repository and its CI untouched.
