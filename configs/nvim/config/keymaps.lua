-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- EasyMotion keybinds are configured in plugins/main.lua
-- They will override LazyVim's default <leader><leader> keybinds

-- Disable space key's default behavior (moving cursor forward) in normal mode
-- This prevents conflicts when space is used as leader key
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })

vim.keymap.set("n", "<A-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<A-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<A-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<A-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- TODO: this causes a notice error:
-- 
-- notify.error noice.nvim ...m/0.11.4/share/nvim/runtime/lua/vim/treesitter/query.lua:373: Query error at 130:4. Invalid node type "substitute":
--  "substitute"
--   ^
-- vim.keymap.set("n", "<C-G><C-G>", ":let @+ = expand('%:p')<CR>", { desc = "Copy full file path" })
vim.keymap.set("n", "<C-G><C-G>", function()
  vim.fn.setreg('+', vim.fn.expand('%:p'))
end, { desc = "Copy full file path" })
-- local M = {}
--
-- M.general = {
--   n = {
--     ["<C-h>"] = { "<cmd> TmuxNavigateLeft<CR>", "window left" },
--     ["<C-l>"] = { "<cmd> TmuxNavigateRight<CR>", "window right" },
--     ["<C-j>"] = { "<cmd> TmuxNavigateDown<CR>", "window down" },
--     ["<C-k>"] = { "<cmd> TmuxNavigateUp<CR>", "window up" },
--   }
-- }


