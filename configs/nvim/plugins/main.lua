-- since this is just an example spec, don't actually load anything here and return an empty spec
-- stylua: ignore
-- if true then return {} end

-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- disable smooth scrolling
  {
    "snacks.nvim",
    opts = {
      scroll = { enabled = false },
    },
  },
  -- {
  --   "coder/claudecode.nvim",
  --   dependencies = { "folke/snacks.nvim" },
  --   config = true,
  --   keys = {
  --     { "<leader>a", nil, desc = "AI/Claude Code" },
  --     { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
  --     { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
  --     { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
  --     { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
  --     { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
  --     { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
  --     { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
  --     {
  --       "<leader>as",
  --       "<cmd>ClaudeCodeTreeAdd<cr>",
  --       desc = "Add file",
  --       ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
  --     },
  --     -- Diff management
  --     { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
  --     { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  --   },
  -- },
  -- {
  --   "greggh/claude-code.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim", -- Required for git operations
  --   },
  --   config = function()
  --     require("claude-code").setup()
  --   end
  -- },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  -- https://github.com/ibhagwan/smartyank.nvim
  -- yank thru ssh / tmux / etc
  {
    'ibhagwan/smartyank.nvim',
    opts = {
      highlight = {
        enabled = false,
      },
      osc52 = {
        escseq = 'tmux',
      },
    },
  },
	-- change trouble config
	{
		"folke/trouble.nvim",
		-- opts will be merged with the parent spec
		opts = { use_diagnostic_signs = true },
	},

	-- override nvim-cmp and add cmp-emoji
	{
		"hrsh7th/nvim-cmp",
		dependencies = { "hrsh7th/cmp-emoji" },
		---@param opts cmp.ConfigSchema
		opts = function(_, opts)
			table.insert(opts.sources, { name = "emoji" })
		end,
	},

	-- change some telescope options and a keymap to browse plugin files
	{
		"nvim-telescope/telescope.nvim",
		keys = {
		-- add a keymap to browse plugin files
		-- stylua: ignore
		{
			"<leader>fp",
			function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
			desc = "Find Plugin File",
		},
		},
		-- change some options
		opts = {
			defaults = {
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
			},
		},
	},

	-- add pyright to lspconfig
	-- {
	-- 	"neovim/nvim-lspconfig",
	-- 	---@class PluginLspOpts
	-- 	opts = {
	-- 		---@type lspconfig.options
	-- 		servers = {
	-- 			-- pyright will be automatically installed with mason and loaded with lspconfig
	-- 			pyright = {},
	-- 			ruff = {
	-- 				cmd_env = { RUFF_TRACE = "messages" },
	-- 				init_options = {
	-- 					settings = {
	-- 						logLevel = "error",
	-- 					},
	-- 				},
	-- 				keys = {
	-- 					{
	-- 						"<leader>co",
	-- 						LazyVim.lsp.action["source.organizeImports"],
	-- 						desc = "Organize Imports",
	-- 					},
	-- 				},
	-- 			},
	-- 			ruff_lsp = {
	-- 				keys = {
	-- 					{
	-- 						"<leader>co",
	-- 						LazyVim.lsp.action["source.organizeImports"],
	-- 						desc = "Organize Imports",
	-- 					},
	-- 				},
	-- 			},
	-- 		},
	-- 		setup = {},
	-- 	},
	-- },

	-- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
	-- treesitter, mason and typescript.nvim. So instead of the above, you can use:

	-- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
	-- would overwrite `ensure_installed` with the new value.
	-- If you'd rather extend the default config, use the code below instead:
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- add tsx and treesitter
      -- this breaks when i have it added for some reason lol
			--  vim.list_extend(opts.ensure_installed, {
			-- 	"tsx",
			-- 	"typescript",
			--      "python",
			--      "lua",
			--      "json",
			--      "javascript",
			--      "yaml",
			--      -- "rust",
			--      "rst",
			--      "ninja",
			--      -- "vim",
			-- })
      opts.highlight = { enable = true }
      opts.indent = { enable = true }
      opts.folds = { enable = true }
		end,
	},

	-- use mini.starter instead of alpha
	-- { import = "lazyvim.plugins.extras.ui.mini-starter" },

	-- EasyMotion for quick navigation (like VSCode vim)
	-- {
	-- 	"easymotion/vim-easymotion",
	-- 	keys = {
	-- 		{ "<leader><leader>s", "<Plug>(easymotion-s)", desc = "Search" },
	-- 		{ "<leader><leader>f", "<Plug>(easymotion-f)", desc = "Find forward" },
	-- 		{ "<leader><leader>F", "<Plug>(easymotion-F)", desc = "Find backward" },
	-- 		{ "<leader><leader>w", "<Plug>(easymotion-w)", desc = "Word forward" },
	-- 		{ "<leader><leader>b", "<Plug>(easymotion-b)", desc = "Word backward" },
	-- 		{ "<leader><leader>j", "<Plug>(easymotion-j)", desc = "Line down" },
	-- 		{ "<leader><leader>k", "<Plug>(easymotion-k)", desc = "Line up" },
	-- 	},
	-- 	config = function()
	-- 		-- Configure EasyMotion like VSCode vim
	-- 		vim.g.EasyMotion_smartcase = 1
	-- 		vim.g.EasyMotion_startofline = 0 -- keep cursor column when JK motion
	-- 	end,
	-- },

	{
		"folke/which-key.nvim",
		opts = function(_, opts)
			opts.spec = opts.spec or {}
			table.insert(opts.spec, {
				"<leader><leader>", 
				group = "+EasyMotion",
				icon = "🏃"
			})
			return opts
		end,
	},

	-- Show dotfiles in Telescope
	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				file_ignore_patterns = {
					-- Remove patterns that hide dotfiles, keep only what you actually want to ignore
					"%.git/",
					"node_modules/",
					"%.cache/",
				},
				hidden = true, -- Show hidden files
			},
			pickers = {
				find_files = {
					hidden = true, -- Show hidden files in find_files
				},
			},
		},
	},

	-- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc

	-- add any tools you want to have installed below
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"stylua",
				"shellcheck",
				"shfmt",
				"flake8",
				"rust-analyzer",
			},
		},
	},

  -- manual saving is prolly better -lena
  -- {
  --   "okuuva/auto-save.nvim",
  --   version = "^1.0.0", -- recommended to use a specific version
  --   event = { "InsertLeave", "TextChanged" }, -- lazy load on these events
  --   opts = {
  --     -- Your desired configuration options for auto-save.nvim
  --     -- For example:
  --     trigger_events = {
  --       immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
  --       defer_save = { "InsertLeave", "TextChanged" },
  --     },
  --     debounce_delay = 1000, -- delay in milliseconds before saving after a change
  --   },
  -- },

  -- {
  --     "numirias/semshi",
  --     build = ":UpdateRemotePlugins",
  -- },
  
  {
    "neovim/nvim-lspconfig",
    opts = {
      autoformat = false,
      inlay_hints = { enabled = true },
    },
  },

  -- {
  --   "nvim-lualine/lualine.nvim",
  --   opts = function(_, opts)
  --     local filename = {
  --       "filename",
  --       path = 1, -- 1 shows the full path
  --     }
  --     opts.sections.lualine_c[1] = filename
  --   end,
  -- },

}
