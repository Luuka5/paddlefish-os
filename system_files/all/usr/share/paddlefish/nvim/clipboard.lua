-- Shared Paddlefish OS clipboard policy for Neovim.
--
-- Prefer a native clipboard provider when a display is available (wl-copy on
-- Wayland, xclip/xsel on X11), which is contained to the local machine and
-- supports reading the "+" register. Otherwise fall back to OSC 52 copy-only so
-- yanks still reach the host clipboard over SSH or in headless containers.
--
-- Reads are intentionally NOT enabled. The terminal is configured with
-- [security] osc52=copy-enabled, and pasting is done with the terminal's own
-- paste binding (foot: Ctrl+Shift+V), which the application cannot trigger.

local function exe(name)
  return vim.fn.executable(name) == 1
end

local wayland = (vim.env.WAYLAND_DISPLAY or "") ~= ""
local x11 = (vim.env.DISPLAY or "") ~= ""
local has_native = (wayland and exe("wl-copy"))
  or (x11 and (exe("xclip") or exe("xsel")))

if has_native then
  -- Let Neovim pick the native provider; full "+"/"*" support.
  vim.opt.clipboard = "unnamedplus"
  return
end

local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if not ok then
  vim.opt.clipboard = ""
  return
end

vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = {
  name = "OSC 52 (copy-only)",
  copy = {
    ["+"] = osc52.copy("+"),
    ["*"] = osc52.copy("*"),
  },
  -- Neovim's provider requires both copy and paste entries to be tables.
  -- Paste is a no-op: reads stay disabled. Use the terminal's paste binding.
  paste = {
    ["+"] = function()
      return {}
    end,
    ["*"] = function()
      return {}
    end,
  },
}
