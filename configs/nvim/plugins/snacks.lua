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
          -- win = {
          --   list = {
          --     keys = {
          --
          --     },
          --   },
          -- },
        },
      },
    },
  },
}

-- https://www.reddit.com/r/neovim/comments/1k7rkfp/comment/mp2j44i/
-- { "\\", desc = "File Explorer", function()
-- 	local explorer_pickers = Snacks.picker.get({ source = "explorer" })
-- 	if #explorer_pickers == 0 then
-- 		Snacks.picker.explorer()
-- 		-- elseif explorer_pickers[1]:is_focused() then
-- 		-- 	explorer_pickers[1]:close()
-- 	else
-- 		explorer_pickers[1]:focus()
-- 	end
-- end },

