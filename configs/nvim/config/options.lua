-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_python_lsp = "basedpyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"

vim.g.lazyvim_picker = "snacks"


vim.g.autoformat = false
vim.opt.relativenumber = true
vim.opt.number = true

vim.opt.sms = false

vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

