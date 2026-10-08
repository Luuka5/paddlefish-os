-- Paddlefish OS color theme for the minimal base-OS Neovim configuration.
--
-- Loaded with dofile() by the base-OS config only; the development container
-- uses the habamax colorscheme instead.
--
-- Colors come from the terminal palette (srcery, see foot.ini and
-- fish/config.fish); termguicolors stays off so Neovim never emits RGB.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

-- Use the terminal palette instead of a colorscheme.
vim.opt.termguicolors = false

-- Darker UI elements following the srcery palette (see foot.ini).
-- srcery bright black (#918175, cterm 8).
vim.cmd("highlight LineNr ctermfg=8")
vim.cmd("highlight SpecialKey ctermfg=8")
vim.cmd("highlight Whitespace ctermfg=8")
