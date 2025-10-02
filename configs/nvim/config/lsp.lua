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

