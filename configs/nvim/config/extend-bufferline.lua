-- https://lazyvim-ambitious-devs.phillips.codes/course/chapter-9/#_navigating_between_open_buffers

return {
	"akinsho/bufferline.nvim",
	keys = {
		{
			"L",
			function()
				vim.cmd("bnext " .. vim.v.count1)
			end,
			desc = "Next buffer",
		},
		{
			"H",
			function()
				vim.cmd("bprev " .. vim.v.count1)
			end,
			desc = "Previous buffer",
		},
		{
			"]b",
			function()
				vim.cmd("bnext " .. vim.v.count1)
			end,
			desc = "Next buffer",
		},
		{
			"[b",
			function()
				vim.cmd("bprev " .. vim.v.count1)
			end,
			desc = "Previous buffer",
		},
	},
}
