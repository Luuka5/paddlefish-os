# Copied configuration provenance

Paddlefish source: `main` at `6a9f6cd7` ("Add ps"), copied on 2026-11-17.

These files are manual copies. They are not included, sourced, symlinked, or
read from the main branch at runtime. Any future upstream change must be copied
and reviewed here, then recorded in this file.

## Copied from Paddlefish

| Destination | Source | Status | Notes |
| --- | --- | --- | --- |
| `config/niri/config.kdl` | `system_files/all/etc/skel/.config/niri/config.kdl` | Pruned | Removed Waybar/nm-applet startup, Waybar toggle, Bluetooth helper binds, swaylock, mako, orca, `playerctl`, and `brightnessctl` binds. Kept Srcery colors, navigation/workspace/layout binds, screenshots, Firefox PiP rule, and `wpctl` volume keys. |
| `config/foot/foot.ini` | `system_files/all/etc/skel/.config/foot/foot.ini` | Adapted | Changed `font=FiraCode Nerd Font Mono:size=9` to `font=FiraCode:size=9`. Colors and OSC 52 copy-only setting unchanged. |
| `config/fuzzel/fuzzel.ini` | `system_files/all/etc/skel/.config/fuzzel/fuzzel.ini` | Adapted | Changed `font=FiraCode Nerd Font Mono:size=12` to `font=FiraCode:size=12`. Colors and layout unchanged. |
| `config/gtk-3.0/settings.ini` | `system_files/all/etc/skel/.config/gtk-3.0/settings.ini` | Verbatim | Dark theme and Adwaita icon theme. |
| `config/gtk-4.0/settings.ini` | `system_files/all/etc/skel/.config/gtk-4.0/settings.ini` | Verbatim | Dark theme preference. |

## Authored for this branch

| File | Purpose |
| --- | --- |
| `README.md` | Standalone build and usage instructions, including the isolation contract. |
| `install.sh` | Idempotent installer for the Armbian image and Orange Pi Zero 3W. |
| `uninstall.sh` | File-only uninstaller with opt-in config purge and temp cleanup. |
| `COPIED.md` | This provenance record. |

## Review checklist for future copies

1. Copy the upstream file into `thin-client/`; never reference it in place.
2. Re-apply the modifications listed above.
3. Run `niri validate --config config/niri/config.kdl`.
4. Update the source commit and notes in this file.
5. Keep the main repository and its CI untouched.
