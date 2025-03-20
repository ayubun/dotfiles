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
  {
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
  -- { "Shatur/neovim-ayu" },
  -- {
  --   "simrat39/rust-tools.nvim",
  --   ft = { "rust" },
  --   config = function()
  --     require("rust-tools").setup {
  --       tools = {
  --         autoSetHints = true,
  --         hover_with_actions = true,
  --         runnables = {
  --           use_telescope = true,
  --         },
  --         inlay_hints = {
  --           show_parameter_hints = true,
  --            parameter_hints_prefix = " <- ",
  --           other_hints_prefix = " => ",
  --         },
  --       },
  --     }
  --   end,
  -- },
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

