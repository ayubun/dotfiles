-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_python_lsp = "basedpyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"

vim.g.lazyvim_picker = "snacks"

-- Handle swap files automatically - prevents E325 ATTENTION errors
vim.opt.swapfile = true  -- Keep swap files for crash recovery
vim.opt.updatecount = 100  -- Update swap file after 100 keystrokes
vim.opt.shortmess:append("A")  -- Don't give ATTENTION message when existing swap file found

vim.g.autoformat = false
vim.opt.relativenumber = false
vim.opt.number = true

vim.opt.sms = false

vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- Optimize scrolling performance - prevents scroll event queueing
-- vim.opt.lazyredraw = true  -- Don't redraw while executing macros/commands
vim.opt.ttyfast = true     -- Assume fast terminal connection
vim.opt.updatetime = 250   -- Faster screen updates (default 4000ms)
vim.opt.timeoutlen = 750   -- Faster key sequence timeout

-- Disable expensive features during scrolling to reduce CPU usage
vim.opt.cursorline = true  -- 
vim.opt.cursorcolumn = false  -- Disable cursor column
vim.opt.scrolloff = 3      -- Reduce scroll offset (less to redraw)
vim.opt.synmaxcol = 200    -- Don't highlight long lines (prevents freeze on minified files)

-- Optimize redraw behavior
vim.opt.redrawtime = 1500  -- Max time for syntax highlighting per command
-- vim.opt.regexpengine = 1   -- Use old regex engine (faster for some patterns)

