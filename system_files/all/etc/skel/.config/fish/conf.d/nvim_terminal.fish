# Neovim's built-in terminal can't render 24-bit (truecolor) SGR sequences,
# so fish's hex prompt colors show up uncolored there. Fall back to 256-color.
if status is-interactive; and set -q NVIM
    set -g fish_term24bit 0
end