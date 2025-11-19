local function setup_keybindings(bufnr)
  local opts = { silent = true, buffer = bufnr }

  vim.keymap.set("n", "<leader>rd", function()
    vim.cmd.RustLsp("openDocs")
  end, vim.tbl_extend("force", opts, { desc = "Open docs" }))

  vim.keymap.set("n", "<leader>re", function()
    vim.cmd.RustLsp("expandMacro")
  end, vim.tbl_extend("force", opts, { desc = "Expand macro" }))

  vim.keymap.set("n", "<leader>rr", function()
    vim.cmd.RustLsp("relatedDiagnostics")
  end, vim.tbl_extend("force", opts, { desc = "Related diagnostics" }))

  vim.keymap.set("n", "<leader>rp", function()
    vim.cmd.RustLsp("rebuildProcMacros")
  end, vim.tbl_extend("force", opts, { desc = "Rebuild proc macros" }))

  vim.keymap.set("n", "<leader>rx", function()
    vim.cmd.RustLsp({ "explainError", "current" })
  end, vim.tbl_extend("force", opts, { desc = "Explain error" }))

  vim.keymap.set("n", "<space>e", function()
    vim.cmd.RustLsp({ "renderDiagnostic", "current" })
  end, vim.tbl_extend("force", opts, { desc = "Open LSP diagnostic float" }))

  vim.keymap.set("n", "K", function()
    vim.cmd.RustLsp({ "hover", "actions" })
  end, vim.tbl_extend("force", opts, { desc = "Show information about symbol at cursor" }))
end

return {
  {
    'mrcjkb/rustaceanvim',
    version = '^6',
    ft = { "rust" },
    -- init = function()
    --   -- Auto-install rust-analyzer component if missing
    --   vim.defer_fn(function()
    --     local handle = io.popen("rustup component list --installed 2>&1 | grep -q rust-analyzer")
    --     local result = handle:read("*a")
    --     handle:close()
    --
    --     if result == "" then
    --       vim.fn.system("rustup component add rust-analyzer")
    --     end
    --   end, 100)
    -- end,
    config = function()
      vim.g.rustaceanvim = {
        tools = {},
        server = {
          -- on_attach = function(client, bufnr)
          --   setup_keybindings()
          -- end,
          default_settings = {
            ["rust-analyzer"] = {
              checkOnSave = true,
              -- check = {
              --   invocationStrategy = "once",
              --   overrideCommand = {
              --     "cargo-subspace",
              --     "clippy",
              --     "$saved_file",
              --   },
              -- },
              -- workspace = {
              --   discoverConfig = {
              --     command = {
              --       "cargo-subspace",
              --       "discover",
              --       "{arg}",
              --     },
              --     progressLabel = "cargo-subspace",
              --     filesToWatch = {
              --       "Cargo.toml",
              --     },
              --   },
              -- },
              numThreads = 16,
            },
          },
        },
        dap = {},
      }
    end,
  },
  -- https://github.com/linrongbin16/gitlinker.nvim
  {
    "linrongbin16/gitlinker.nvim",
    cmd = "GitLink",
    opts = {},
    keys = {
      { "<leader>gy", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Yank git link" },
      { "<leader>gY", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open git link" },
    },
  },
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
      opts.highlight = {
        enable = true,
        -- Disable highlighting for large files to prevent CPU spikes
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
        -- Use a smaller chunk size for incremental parsing
        additional_vim_regex_highlighting = false,
      }
      opts.indent = { enable = true }
      opts.folds = { enable = true }
		end,
	},

	-- {
	-- 	"folke/which-key.nvim",
	-- 	opts = function(_, opts)
	-- 		opts.spec = opts.spec or {}
	-- 		table.insert(opts.spec, {
	-- 			"<leader><leader>", 
	-- 			group = "+EasyMotion",
	-- 			icon = "🏃"
	-- 		})
	-- 		return opts
	-- 	end,
	-- },
	--


	-- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc

	-- add any tools you want to have installed below
	{
		"mason-org/mason.nvim",
		opts = {
      -- ensure_installed = {
      --   -- "rust-analyzer", -- rust
      --   "lua-language-server", -- lua
      --   "terraform-ls", -- terraform
      --   "taplo", -- toml
      --   "json-lsp", -- json
      --   "ruff",
      --   "pyright",
      --   "mypy",
      --   "vtsls",
      -- },
		},
	},
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- Explicitly disable rust_analyzer setup - rustaceanvim handles it
      handlers = {
        -- MUST provide default handler when using handlers table
        function(server_name)
          require("lspconfig")[server_name].setup({})
        end,
        -- Override rust_analyzer to do nothing
        rust_analyzer = function() end,
      },
    },
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      autoformat = false,
      inlay_hints = { enabled = true },
      -- Prevent LazyVim from auto-setting up rust_analyzer (we use rustaceanvim instead)
      servers = {
        rust_analyzer = {
          -- Set to false to prevent automatic setup by LazyVim
          enabled = false,
        },
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
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   version = false, -- Never set this value to "*"! Never!
  --   build = "make",
  --   config = function()
  --     require("config.avante")
  --   end,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --     --- The below dependencies are optional,
  --     "nvim-mini/mini.pick", -- for file_selector provider mini.pick
  --     -- "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
  --     "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
  --     -- "ibhagwan/fzf-lua", -- for file_selector provider fzf
  --     "stevearc/dressing.nvim", -- for input provider dressing
  --     "folke/snacks.nvim", -- for input provider snacks
  --     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  --     -- "zbirenbaum/copilot.lua", -- for providers='copilot'
  --     {
  --       -- support for image pasting
  --       "HakonHarnes/img-clip.nvim",
  --       event = "VeryLazy",
  --       opts = {
  --         -- recommended settings
  --         default = {
  --           embed_image_as_base64 = false,
  --           prompt_for_file_name = false,
  --           drag_and_drop = {
  --             insert_mode = true,
  --           },
  --           -- required for Windows users
  --           use_absolute_path = true,
  --         },
  --       },
  --     },
  --     {
  --       -- Make sure to set this up properly if you have lazy=true
  --       'MeanderingProgrammer/render-markdown.nvim',
  --       opts = {
  --         file_types = { "markdown", "Avante" },
  --       },
  --       ft = { "markdown", "Avante" },
  --     },
  --   },
  -- },
}
