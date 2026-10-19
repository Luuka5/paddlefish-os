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

### Clipboard

Neovim uses a native clipboard provider when a display is available
(`wl-clipboard` on Wayland, `xclip`/`xsel` on X11), so the `+`/`*` registers
work normally. Where there is no display — an SSH session or a headless
container — it falls back to OSC 52 **copy-only**: yanks still reach the host
clipboard, but programs can never read it. Paste with the terminal's own
binding (`Ctrl+Shift+V` in foot); this is enforced by `[security]
osc52=copy-enabled` in `foot.ini`, so no application can read the clipboard
without a keypress. See `system_files/all/usr/share/paddlefish/nvim/clipboard.lua`.

## Development containers

Separate development container images live alongside the OS images. They are
run on demand, one instance per project directory, and are not part of the
installed OS. Basic tooling (fish, zoxide, vim, git, ripgrep, fd, fzf,
wl-clipboard, podman client) is unified with the server image via
`scripts/base.sh`; the language toolchains and agents are dev-only.

| Variant | Purpose |
|---------|---------|
| `paddlefish-dev-core` | CLI toolchains and agents, no GUI/GPU stack |
| `paddlefish-dev-gui` | core plus mesa/radv/anv/lavapipe for AMD/Intel/software GPUs |
| `paddlefish-dev-nvidia` | gui plus NVIDIA CDI glue and the CUDA toolkit (driver libs come from the host) |

Each image includes: Node.js + npm + pnpm + bun + TypeScript + Tailwind CLI,
Rust via rustup (with clang + mold and the Bevy Linux build deps), Go + gopls,
a C/C++ toolchain (gcc, clang, clangd, cmake, ninja, gdb/lldb), and pinned
`opencode` and `pi` coding agents. The nvidia variant adds `cuda-toolkit`. The
Neovim config is fuller than the base OS: it bootstraps lazy.nvim and Mason and
installs LSP servers, and uses the `habamax` colorscheme with true color (the
base OS keeps the terminal's srcery palette). All config is baked into the
image's `/home/dev`; there is no per-project home volume and no seeding.

### Run

```sh
./scripts/paddlefish-dev                     # core, fish shell in /workspace
./scripts/paddlefish-dev --local             # build from source instead of pulling
./scripts/paddlefish-dev --gui               # share the Wayland/X11 session
./scripts/paddlefish-dev --gpu=amd           # AMD/Intel GPU via /dev/dri
./scripts/paddlefish-dev --gpu=nvidia        # NVIDIA via CDI
./scripts/paddlefish-dev -p 3000:3000        # publish a port (repeatable)
./scripts/paddlefish-dev --net=host          # host networking (no -p)
./scripts/paddlefish-dev --podman            # podman-in-podman sidecar
./scripts/paddlefish-dev -- cargo test       # run a command instead of a shell
./scripts/paddlefish-dev --clean             # remove this project's container
./scripts/paddlefish-dev --clean-cache       # remove shared caches (all projects)
```

Images are pulled from GHCR (`ghcr.io/<owner>/paddlefish-dev-<variant>:latest`)
by default; use `--local` (or `--build`) to build them from this repo instead.
Every project directory gets its own container and (with `--podman`) sidecar,
derived from the directory path; `--clean` removes them and `--recreate`
rebuilds the container.
The project directory is bind-mounted at `/workspace` and set as the working
directory; the container hostname is the directory name. SELinux labeling is
disabled for the container (`--security-opt label=disable`), so host binds and
the Wayland/GPU sockets work without relabeling. `$HOME` is the image's
`/home/dev` (ephemeral per container), so config updates ship automatically with
the image; shell history and `sudo`-installed packages do not survive a
recreate. Package caches live in shared, project-independent volumes (`~/.cache`,
cargo registry/git, npm, bun, pnpm, Go module cache, nvim plugins/LSPs) so they
persist and are reused by every project. The `dev` user has passwordless
`sudo`. Release pins live in `scripts/dev/versions.env`.

With `--podman`, the sidecar runs a nested podman (using `fuse-overlayfs`) and
shares the project directory at `/workspace`, so bind mounts into it from the
sidecar resolve. Short image names resolve to `docker.io` without a TTY prompt
(`registries.conf.d` drop-in). Changing the sidecar's configuration requires
recreating it (`--clean`).

### Build manually

```sh
./scripts/dev/build.sh core        # or: gui | nvidia | all
```

Requires host packages for the GUI/GPU options: `--gui` needs the host Wayland
session, `--gpu=amd` needs the host user in the `video`/`render` groups (used
with `--group-add keep-groups`, crun), and `--gpu=nvidia` needs the CDI
provisioned by the `desktop-nvidia` image.
