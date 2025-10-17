return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  enabled = true,
  opts = function(_, opts)
  --   table.remove(opts.sections.lualine_c, 1)
  --   table.remove(opts.sections.lualine_c, #opts.sections.lualine_c)
  --   table.insert(opts.sections.lualine_c, {
  --     "filename",
  --     path = 3,
  --   })
  --   -- local filename = {
  --   --   "filename",
  --   --   path = 1,
  --   -- }
  --   -- opts.sections.lualine_c[1] = filename
    opts.sections.lualine_c[4] = { LazyVim.lualine.pretty_path({
      length = 12,
    }) }
  end,
  -- opts = {
  --   sections = {
  --     lualine_a = { "mode" },
  --     lualine_b = { "branch", "diff", "diagnostics" },
  --     lualine_c = {
  --       {
  --         "filename",
  --         path = 3, -- 1 for filename only, 2 for relative path, 3 for full path
  --         file_status = true,
  --         shorting_target = 60,
  --         max_length = 100,
  --       },
  --     },
  --     -- ... other sections ...
  --   },
  -- },
}
