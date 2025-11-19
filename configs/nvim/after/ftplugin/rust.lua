local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "<leader>a", function()
	vim.cmd.RustLsp("codeAction") -- supports rust-analyzer's grouping
	-- or vim.lsp.buf.codeAction() if you don't want grouping.
end, { silent = true, buffer = bufnr })

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
--
-- vim.keymap.set(
--   "n",
--   "K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
--   function()
--     vim.cmd.RustLsp({ "hover", "actions" })
--   end,
--   { silent = true, buffer = bufnr }
-- )
