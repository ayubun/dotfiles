require("lspconfig").rust_analyzer.setup({
    settings = {
        ["rust-analyzer"] = {
            completion = {
                autoimport = {
                    enable = true,
                },
            },
            -- Other rust-analyzer settings...
        },
    },
    -- Other LSP configuration options...
})

