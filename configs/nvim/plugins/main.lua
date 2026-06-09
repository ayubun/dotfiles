return {
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
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
              check = {
                invocationStrategy = "once",
                overrideCommand = {
                  "cargo-subspace",
                  "clippy",
                  "$saved_file",
                },
              },
              workspace = {
                discoverConfig = {
                  command = {
                    "cargo-subspace",
                    "discover",
                    "{arg}",
                  },
                  progressLabel = "cargo-subspace",
                  filesToWatch = {
                    "Cargo.toml",
                  },
                },
              },
              numThreads = 16,
            },
          },
        },
        dap = {},
      }
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_start = 0

      -- On a remote host (always Linux in this setup) the browser lives on the
      -- local Mac. Serve the preview on a localhost port that SSH forwards back
      -- to the Mac (LocalForward of the 48923-48932 range, see
      -- configs/ssh/lemonade.conf), and hand the URL to `lemonade open` so it
      -- opens in the Mac's browser via the SSH reverse tunnel (RemoteForward 2489).
      -- See also configs/lemonade.toml.
      --
      -- The missing piece before was mkdp_browserfunc: without it, mkdp tried to
      -- open a browser on the *remote* itself instead of shipping the URL home.
      --
      -- On the Mac (has("mac") == 1) the default behavior is kept: mkdp just
      -- opens the local browser directly.
      local is_remote = vim.fn.has("mac") == 0
      if is_remote then
        -- Each nvim instance grabs its own free port from the forwarded range so
        -- multiple instances (e.g. separate tmux panes / SSH sessions) can preview
        -- at the same time. NOTE: multiple markdown buffers within ONE nvim already
        -- share a single server via /page/<bufnr> paths, so this is only about
        -- running several *separate* nvims. Keep this range in sync with the
        -- LocalForward lines in configs/ssh/lemonade.conf.
        local PORT_FIRST, PORT_LAST = 48923, 48927
        local function pick_free_port(first, last)
          local uv = vim.uv or vim.loop
          local count = last - first + 1
          -- Start at a pid-derived offset so concurrent instances spread across
          -- the range instead of all racing for the first port.
          local offset = vim.fn.getpid() % count
          for i = 0, count - 1 do
            local port = first + ((offset + i) % count)
            local server = uv.new_tcp()
            if server then
              local ok = pcall(function()
                assert(server:bind("127.0.0.1", port))
              end)
              server:close()
              if ok then
                return port
              end
            end
          end
          return first -- range exhausted; fall back to the first port
        end

        vim.g.mkdp_open_to_the_world = 0 -- bind 127.0.0.1 only (private to the box)
        vim.g.mkdp_open_ip = "127.0.0.1" -- URL host the Mac browser will hit
        vim.g.mkdp_port = tostring(pick_free_port(PORT_FIRST, PORT_LAST))
        vim.g.mkdp_echo_preview_url = 1 -- also echo the URL in nvim as a fallback
        vim.g.mkdp_browserfunc = "MkdpLemonadeOpen"
        vim.cmd([[
          function! MkdpLemonadeOpen(url) abort
            if executable('lemonade')
              call jobstart(['lemonade', 'open', a:url])
            else
              echohl WarningMsg
              echom '[markdown-preview] lemonade not found in PATH; open manually: ' . a:url
              echohl None
            endif
          endfunction
        ]])
      end
    end,
    ft = { "markdown" },
  },
  -- this syncs neovim's env with the one that the user has
  { "direnv/direnv.vim" },
  -- https://github.com/avifenesh/claucode.nvim
  -- {
  --   "avifenesh/claucode.nvim",
  --   config = function()
  --     require("claucode").setup()
  --   end,
  -- },
  {
    "nickjvandyke/opencode.nvim",
    version = "*", -- Latest stable release
    dependencies = {
      {
        -- `snacks.nvim` integration is recommended, but optional
        ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {}, -- Enhances `ask()`
          picker = { -- Enhances `select()`
            actions = {
              opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
            },
            win = {
              input = {
                keys = {
                  ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any; goto definition on the type or field for details
      }

      vim.o.autoread = true -- Required for `opts.events.reload`

      -- Recommended/example keymaps
      vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
      vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,                          { desc = "Select opencode…" })
      -- vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end,                          { desc = "Toggle opencode" })

      vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("@this ") end,        { desc = "Add range to opencode", expr = true })
      vim.keymap.set("n",          "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,   { desc = "Scroll opencode up" })
      vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })

      -- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap)
      --
      vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
      vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
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

	-- configure blink.cmp (LazyVim's default completion engine)
	{
		"saghen/blink.cmp",
		opts = {
			fuzzy = { implementation = "lua" },
		},
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
      -- -- Prevent LazyVim from auto-setting up rust_analyzer (we use rustaceanvim instead)
      -- servers = {
      --   rust_analyzer = {
      --     -- Set to false to prevent automatic setup by LazyVim
      --     enabled = false,
      --   },
      -- },
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
