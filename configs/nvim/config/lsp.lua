local lspconfig = require("lspconfig")

lspconfig.rust_analyzer.setup({
    settings = {
        ["rust-analyzer"] = {
            completion = {
                autoimport = {
                    enable = true,
                },
            },
            checkOnSave = {
                command = "clippy",
            },
            check = {
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

