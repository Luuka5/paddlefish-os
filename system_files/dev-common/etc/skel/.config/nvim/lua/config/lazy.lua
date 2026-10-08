-- lazy.nvim bootstrap and setup.
--
-- Clones lazy.nvim into the Neovim data dir on first launch and lets it manage
-- all other plugins. The data dir (~/.local/share/nvim) is a shared volume, so
-- plugins are installed once and reused by every project.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
