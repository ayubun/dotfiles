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
    },
    explorer = {
      filter = function(file)
        -- Ignore common directories that cause performance issues
        local ignore_patterns = {
          "^%.git/",
          "^node_modules/",
          "^%.cache/",
          "^tmp/",
          "^build/",
          "^dist/",
          "^target/",
          "^%.local/",
        }
        for _, pattern in ipairs(ignore_patterns) do
          if file:match(pattern) then
            return false
          end
        end
        return true
      end,
      diagnostics = false,
      git = false,
    },
  },
}
