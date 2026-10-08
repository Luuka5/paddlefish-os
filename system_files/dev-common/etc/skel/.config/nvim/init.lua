-- Paddlefish OS development-container Neovim configuration.
--
-- Unlike the minimal base-OS config, this one uses a plugin manager
-- (lazy.nvim) and installs plugins/LSP servers on first launch. Plugin and LSP
-- state lives in ~/.local/share/nvim (a shared cache volume). Unlike the base
-- OS, which uses the terminal's srcery palette, this config uses the habamax
-- colorscheme with true color.

-- [[ Leader ]]
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- [[ Options ]]
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "nosplit"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.cursorline = true
vim.opt.breakindent = true
vim.opt.hidden = true
vim.opt.confirm = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 10
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.signcolumn = "yes"
-- Shared clipboard policy (native-first, OSC 52 copy-only fallback).
dofile("/usr/share/paddlefish/nvim/clipboard.lua")
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- [[ Security ]]
vim.opt.modeline = false
vim.opt.modelines = 0
vim.opt.exrc = false

-- [[ Keymaps ]]
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", opts)
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", opts)
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", opts)
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", opts)

-- [[ Autocommands ]]
local group = vim.api.nvim_create_augroup("paddlefish-dev", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Plugins ]]
require("config.lazy")

-- Dev-container colorscheme: habamax, with full RGB (the host terminal, foot,
-- supports true color).
vim.opt.termguicolors = true
vim.cmd.colorscheme("habamax")
