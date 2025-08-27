-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- EasyMotion keybinds are configured in plugins/main.lua
-- They will override LazyVim's default <leader><leader> keybinds

-- Disable space key's default behavior (moving cursor forward) in normal mode
-- This prevents conflicts when space is used as leader key
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })
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
