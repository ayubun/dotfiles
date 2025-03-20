-- LazyVim configuration file
-- ~/.config/nvim/init.lua

-- General settings
vim.opt.clipboard = "unnamedplus"
vim.g.autoformat = true
vim.g.mapleader = " " -- Make sure space is your leader key

-- Colorscheme
vim.cmd("colorscheme nordfox")

-- Keybindings
vim.keymap.set("n", "gt", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "gT", ":BufferLineCyclePrev<CR>", { silent = true })

-- Terminal mappings - these replace the which-key configuration
vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm<cr>", { desc = "Floating terminal" })
vim.keymap.set("n", "<leader>tv", "<cmd>2ToggleTerm size=30 direction=vertical<cr>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>th", "<cmd>2ToggleTerm size=30 direction=horizontal<cr>", { desc = "Split horizontal" })

-- LazyVim custom plugins setup
-- Place this in ~/.config/nvim/lua/plugins/custom.lua
return {
	-- Show hidden files in file explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			filesystem = {
				filtered_items = {
					visible = true, -- Equivalent to showing hidden files
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
		},
	},
	-- Nightfox theme
	{
		"EdenEast/nightfox.nvim",
		lazy = false,
		priority = 1000,
	},
	-- goto-preview plugin
	{
		"rmagatti/goto-preview",
		dependencies = { "rmagatti/logger.nvim" },
		event = "BufEnter",
		config = function()
			require("goto-preview").setup({
				width = 120,
				height = 15,
				border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" },
				default_mappings = true,
				debug = false,
				opacity = nil,
				resizing_mappings = false,
				post_open_hook = nil,
				post_close_hook = nil,
				references = {
					provider = "telescope",
					telescope = require("telescope.themes").get_dropdown({ hide_preview = false }),
				},
				focus_on_open = true,
				dismiss_on_move = false,
				force_close = true,
				bufhidden = "wipe",
				stack_floating_preview_windows = true,
				same_file_float_preview = true,
				preview_window_title = { enable = true, position = "left" },
				zindex = 1,
				vim_ui_input = true,
			})
		end,
	},
	-- Smartyank plugin
	{
		"ibhagwan/smartyank.nvim",
		opts = {
			highlight = {
				enabled = false,
			},
		},
	},
	-- Copilot setup
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					keymap = {
						accept = "<c-l>",
						next = "<c-j>",
						prev = "<c-k>",
						dismiss = "<c-h>",
					},
				},
			})
			-- Toggle auto-trigger keybinding
			vim.keymap.set(
				"n",
				"<c-s>",
				"<cmd>lua require('copilot.suggestion').toggle_auto_trigger()<CR>",
				{ noremap = true, silent = true }
			)
		end,
	},
	-- Copilot CMP integration
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	-- Git blame
	{
		"f-person/git-blame.nvim",
		event = "BufRead",
		config = function()
			vim.cmd("highlight default link gitblame SpecialComment")
			vim.g.gitblame_enabled = 1
		end,
	},
	-- Easymotion
	{
		"easymotion/vim-easymotion",
		event = "VeryLazy",
	},
	-- Add ToggleTerm if it's not already included in LazyVim
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = true,
	},
}
