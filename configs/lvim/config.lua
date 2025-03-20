-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- configs 
lvim.builtin.lir.show_hidden_files = true
lvim.colorscheme = "nordfox"

-- keybinds
lvim.keys.normal_mode["gt"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["gT"] = ":BufferLineCyclePrev<CR>"

-- https://github.com/LunarVim/LunarVim/discussions/3794#discussioncomment-4821693
lvim.builtin.which_key.mappings["t"] = {
  name = "+Terminal",
  f = { "<cmd>ToggleTerm<cr>", "Floating terminal" },
  v = { "<cmd>2ToggleTerm size=30 direction=vertical<cr>", "Split vertical" },
  h = { "<cmd>2ToggleTerm size=30 direction=horizontal<cr>", "Split horizontal" },
}

vim.opt.clipboard = "unnamedplus"

-- copilot tutorial: https://medium.com/aimonks/a-guide-to-integrating-lunarvim-github-copilot-61d92f764913
lvim.plugins = {
  {  -- https://github.com/rmagatti/goto-preview
    "rmagatti/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
    event = "BufEnter",
    config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
  },
  {  -- https://github.com/ibhagwan/smartyank.nvim
    'ibhagwan/smartyank.nvim',
    opts = {
      highlight = {
        enabled = false,
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
  },
  {
    "zbirenbaum/copilot-cmp",
    after = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },
  {
    "f-person/git-blame.nvim",
    event = "BufRead",
    config = function()
      vim.cmd "highlight default link gitblame SpecialComment"
      vim.g.gitblame_enabled = 1
    end,
  },
  { "EdenEast/nightfox.nvim" },
  { "easymotion/vim-easymotion" },
}

local ok, copilot = pcall(require, "copilot")
if not ok then
  return
end

copilot.setup {
  suggestion = {
    keymap = {
      accept = "<c-l>",
      next = "<c-j>",
      prev = "<c-k>",
      dismiss = "<c-h>",
    },
  },
}

local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<c-s>", "<cmd>lua require('copilot.suggestion').toggle_auto_trigger()<CR>", opts)

require('goto-preview').setup {
  width = 120, -- Width of the floating window
  height = 15, -- Height of the floating window
  border = {"↖", "─" ,"┐", "│", "┘", "─", "└", "│"}, -- Border characters of the floating window
  default_mappings = true, -- Bind default mappings
  debug = false, -- Print debug information
  opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
  resizing_mappings = false, -- Binds arrow keys to resizing the floating window.
  post_open_hook = nil, -- A function taking two arguments, a buffer and a window to be ran as a hook.
  post_close_hook = nil, -- A function taking two arguments, a buffer and a window to be ran as a hook.
  references = { -- Configure the telescope UI for slowing the references cycling window.
    provider = "telescope", -- telescope|fzf_lua|snacks|mini_pick|default
    telescope = require("telescope.themes").get_dropdown({ hide_preview = false })
  },
  -- These two configs can also be passed down to the goto-preview definition and implementation calls for one off "peak" functionality.
  focus_on_open = true, -- Focus the floating window when opening it.
  dismiss_on_move = false, -- Dismiss the floating window when moving the cursor.
  force_close = true, -- passed into vim.api.nvim_win_close's second argument. See :h nvim_win_close
  bufhidden = "wipe", -- the bufhidden option to set on the floating window. See :h bufhidden
  stack_floating_preview_windows = true, -- Whether to nest floating windows
  same_file_float_preview = true, -- Whether to open a new floating window for a reference within the current file
  preview_window_title = { enable = true, position = "left" }, -- Whether to set the preview window title as the filename
  zindex = 1, -- Starting zindex for the stack of floating windows
  vim_ui_input = true, -- Whether to override vim.ui.input with a goto-preview floating window
}

