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
        -- diagnosticMode = "workspace",
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
        reportCallIssue = "none",
        disableOrganizeImports = true,
      },
    },
  },
})

