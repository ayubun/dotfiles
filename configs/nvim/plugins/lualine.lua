local icons = LazyVim.config.icons

return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	enabled = true,
	opts = {
	  sections = {
      -- this code is a copy of the lazyvim setup, with the simple change of overwriting pretty_path length from defaulting to 3 -> 12
      -- https://github.com/LazyVim/LazyVim/blob/048056e9523268d6086d537e578e84e27175051d/lua/lazyvim/plugins/ui.lua#L97-L110
	    lualine_c = {
        LazyVim.lualine.root_dir(),
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { LazyVim.lualine.pretty_path({ length = 12 }) },
	    },
	  },
	},
}
