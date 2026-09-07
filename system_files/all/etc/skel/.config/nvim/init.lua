-- Minimal Neovim configuration.
--
-- Deliberately minimal: no plugin manager (no lazy.nvim / vim.pack / mason)
-- and nothing fetched from the network at runtime. The only plugins are
-- telescope.nvim + plenary, vendored system-wide at image build time at
-- pinned commit SHAs (see scripts/nvim-plugins.sh). Colors come from the
-- terminal palette; external tools (ripgrep, fd, ...) are distro packages.
--
-- https://neovim.io/doc/user/

-- [[ Terminal colors ]]
-- Clear all highlighting and use the 16-color terminal ANSI palette (srcery)
-- instead of loading a colorscheme.
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

-- termguicolors off so Neovim uses the terminal palette, not RGB colors.
vim.opt.termguicolors = false

-- Darker UI elements following the srcery palette (see foot.ini).
-- srcery bright black (#918175, cterm 8).
vim.cmd("highlight LineNr ctermfg=8")
vim.cmd("highlight SpecialKey ctermfg=8")
vim.cmd("highlight Whitespace ctermfg=8")

-- Share the OS clipboard (requires the wl-clipboard package on Wayland).
vim.o.clipboard = "unnamedplus"

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

-- Show whitespace markers (tabs, trailing, nbsp).
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- [[ Security ]]
-- Never evaluate modelines or source a repository-local config (.nvimrc):
-- opening an untrusted file must not be able to change options or run code.
vim.opt.modeline = false
vim.opt.modelines = 0
vim.opt.exrc = false

-- [[ Keymaps ]]
local opts = { noremap = true, silent = true }

-- <Esc> clears search highlighting.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- Leave terminal mode (easier than the default <C-\><C-n>).
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

-- Move between split windows.
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", opts)
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", opts)
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", opts)
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", opts)

-- [[ Autocommands ]]
-- Briefly highlight the yanked text.
local group = vim.api.nvim_create_augroup("highlight-yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Open a terminal (fish) by default when nvim is started without file arguments.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() > 0 then
      return
    end
    vim.cmd("terminal")
  end,
})

-- [[ Search (telescope) ]]
-- Search is backed by vendored telescope.nvim + plenary (scripts/nvim-plugins.sh):
-- pinned SHAs, installed system-wide at image build, nothing fetched at runtime.
--
-- The <Space>s* keys are bound unconditionally and telescope is required lazily
-- on first use, so a missing or partial install (image built before vendoring,
-- or a non-image machine) shows a warning instead of dead keys. A one-time
-- warning is also emitted at startup when telescope is absent.
if not pcall(require, "telescope") then
  vim.notify(
    "nvim search pickers unavailable: telescope.nvim was not found. Rebuild and "
      .. "reflash the image (scripts/nvim-plugins.sh), or vendor plenary.nvim and "
      .. "telescope.nvim into ~/.config/nvim/pack (see scripts/nvim-plugin-shas).",
    vim.log.levels.WARN
  )
end

local search_setup_done = false
local search = function(key, label, action)
  vim.keymap.set("n", key, function()
    local ok, err = pcall(require, "telescope")
    if not ok then
      vim.notify(
        "nvim search pickers unavailable: telescope.nvim was not found (" .. err .. ")",
        vim.log.levels.WARN
      )
      return
    end
    if not search_setup_done then
      pcall(require("telescope").setup, {})
      search_setup_done = true
    end
    action(require("telescope.builtin"))
  end, { desc = label })
end

search("<leader>sh", "[S]earch [H]elp", function(b) b.help_tags() end)
search("<leader>sk", "[S]earch [K]eymaps", function(b) b.keymaps() end)
search("<leader>sf", "[S]earch [F]iles", function(b) b.find_files() end)
search("<leader>ss", "[S]earch [S]elect Telescope", function(b) b.builtin() end)
search("<leader>sw", "[S]earch current [W]ord", function(b) b.grep_string() end)
search("<leader>sg", "[S]earch by [G]rep", function(b) b.live_grep() end)
search("<leader>sd", "[S]earch [D]iagnostics", function(b) b.diagnostics() end)
search("<leader>sr", "[S]earch [R]esume", function(b) b.resume() end)
search("<leader>s.", "[S]earch recent files", function(b) b.oldfiles() end)
search("<leader>sc", "[S]earch [C]ommands", function(b) b.commands() end)
search("<leader><leader>", "[ ] Find existing buffers", function(b) b.buffers() end)
search("<leader>/", "Fuzzily search in current buffer", function(b)
  b.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown { winblend = 10 })
end)
search("<leader>s/", "[S]earch [/] in open files", function(b)
  b.live_grep { grep_open_files = true }
end)
search("<leader>sn", "[S]earch [N]eovim files", function(b)
  b.find_files { cwd = vim.fn.stdpath "config", follow = true }
end)
