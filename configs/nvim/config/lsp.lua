local lspconfig = require("lspconfig")

-- Fix vtsls root_dir bug where vim.fs.root returns table instead of string
lspconfig.vtsls.setup({
  root_dir = function(fname)
    local util = require("lspconfig.util")
    return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)
  end,
})



lspconfig.rust_analyzer.setup({
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = false,  -- Don't analyze all features
        buildScripts = {
          enable = false,  -- Disable build script analysis
        },
        loadOutDirsFromCheck = false,  -- Don't load OUT_DIR values from cargo check
      },
      checkOnSave = {
        enable = true,
        command = "clippy",
        extraArgs = { "--no-deps" },  -- Don't check dependencies
      },
      procMacro = {
        enable = false,  -- Disable proc macro expansion
      },
      diagnostics = {
        enable = true,
        disabled = {},
        experimental = {
          enable = false,  -- Disable experimental diagnostics
        },
        refreshSupport = false,  -- Don't auto-refresh diagnostics
      },
      lens = {
        enable = false,  -- Disable code lens (saves CPU)
      },
      hover = {
        actions = {
          enable = false,
        },
      },
      completion = {
          autoimport = {
              enable = true,
          },
      },
      inlayHints = {
        enable = true,
      },
      -- check = {
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
    },
  },
})

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

