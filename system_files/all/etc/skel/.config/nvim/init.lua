-- https://neovim.io/doc/user/

-- Clear current highlighting
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

-- Ensure termguicolors is disabled so Neovim uses 16-color terminal ANSI palette
vim.opt.termguicolors = false
