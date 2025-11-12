return {
  "folke/snacks.nvim",
  opts = {
    scroll = {
      enabled = false,
    },
    picker = {
      formatters = {
        file = {
          truncate = 120,
        },
      },
      sources = {
        explorer = {
          diagnostics = false,
          diagnostics_open = false,
          -- git_status = false,
          -- git_status_open = false,
        },
      },
    },
  },
}
