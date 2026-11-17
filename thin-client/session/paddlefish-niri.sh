#!/bin/sh

# Start niri automatically after a manual login on tty1.
# PADDLEFISH_NIRI_AUTO prevents recursion because niri-session re-execs
# a login shell before starting the compositor.

[ -n "${PADDLEFISH_NIRI_AUTO:-}" ] && return 0
[ "$(id -u)" -ge 1000 ] || return 0
[ -t 0 ] || return 0
[ "$(tty)" = "/dev/tty1" ] || return 0
[ -z "${WAYLAND_DISPLAY:-}" ] || return 0
[ -z "${DISPLAY:-}" ] || return 0
command -v niri-session >/dev/null 2>&1 || return 0
[ -x /usr/libexec/paddlefish/niri-session ] || return 0

export PADDLEFISH_NIRI_AUTO=1
exec /usr/libexec/paddlefish/niri-session
