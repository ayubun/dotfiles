local lspconfig = require("lspconfig")

-- Fix vtsls root_dir bug where vim.fs.root returns table instead of string
lspconfig.vtsls.setup({
  root_dir = function(fname)
    local util = require("lspconfig.util")
    return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
  end,
})



-- lspconfig.rust_analyzer.setup({
--   settings = {
--     ["rust-analyzer"] = {
--       check = {
--         invocationStrategy = "once",
--         overrideCommand = {
--           "cargo-subspace",
--           "clippy",
--           "$saved_file",
--         },
--       },
--       workspace = {
--         discoverConfig = {
--           command = {
--             "cargo-subspace",
--             "discover",
--             "{arg}",
--           },
--           progressLabel = "cargo-subspace",
--           filesToWatch = {
--             "Cargo.toml",
--           },
--         },
--       },
--       -- procMacro = {
--       --   enable = false,  -- Disable proc macro expansion
--       -- },
--     },
--   },
-- })

vim.g.rustaceanvim = {
  -- Plugin configuration
  tools = {
  },
  -- LSP configuration
  server = {
    on_attach = function(client, bufnr)
      -- you can also put keymaps in here
    end,
    default_settings = {
      -- rust-analyzer language server configuration
      ['rust-analyzer'] = {
        check = {
          command = "check",
          extraArgs = { "--profile", "rust-analyzer" },
          workspace = false,
        },
        cachePriming = {
          enable = false,
        },
        procMacro = {
          enable = true,
          ignored = {
            ["async-trait"] = { "async_trait" },
            ["napi-derive"] = { "napi" },
            ["async-recursion"] = { "async_recursion" },
          },
        },
        -- linkedProjects = { '/home/discord/dev/Cargo.toml' },
        workspace = {
          symbol = {
            search = {
              kind = "only_types",
              scope = "workspace",
            },
          },
        },
      },
    },
  },
  -- DAP configuration
  dap = {
  },
}

lspconfig.basedpyright.setup({
  root_dir = function(fname)
    -- Look for uv.lock or .git in parent directories to find the workspace root
    local util = require("lspconfig.util")
    return util.root_pattern("uv.lock", ".git")(fname)
  end,
  settings = {
    basedpyright = {
      analysis = {
        ignorePatterns = { "*.pyi" },
        diagnosticSeverityOverrides = {
          reportCallIssue = "warning",
          reportUnreachable = "warning",
          reportUnusedImport = "none",
          reportUnusedCoroutine = "warning",
        },
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
        reportCallIssue = "none",
        disableOrganizeImports = true,
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
    -- python = {
    --   pythonPath = ".venv/bin/python",
    --   venvPath = ".",
    --   analysis = {
    --     autoSearchPaths = true,
    --     useLibraryCodeForTypes = true,
    --   },
    -- },
  },
})

