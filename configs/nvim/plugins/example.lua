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
  -- https://github.com/ibhagwan/smartyank.nvim
  -- yank thru ssh / tmux / etc
  {
    'ibhagwan/smartyank.nvim',
    opts = {
      highlight = {
        enabled = false,
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
	{ import = "lazyvim.plugins.extras.lang.typescript" },

	-- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
	-- would overwrite `ensure_installed` with the new value.
	-- If you'd rather extend the default config, use the code below instead:
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- add tsx and treesitter
			vim.list_extend(opts.ensure_installed, {
				"tsx",
				"typescript",
        -- "python",
        -- "lua",
        -- "json",
        -- "javascript",
        -- "yaml",
        -- "rust",
        -- "rst",
        -- "ninja",
        -- "vim",
			})
		end,
	},

	-- use mini.starter instead of alpha
	{ import = "lazyvim.plugins.extras.ui.mini-starter" },

	-- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
	{ import = "lazyvim.plugins.extras.lang.json" },

	-- add any tools you want to have installed below
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"stylua",
				"shellcheck",
				"shfmt",
				"flake8",
			},
		},
	},
}
