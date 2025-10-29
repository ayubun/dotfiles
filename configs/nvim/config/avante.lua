require("avante").setup({
	-- -- add any opts here
	-- -- this file can contain specific instructions for your project
	-- instructions_file = "avante.md",
	-- for example
	provider = "claude",
	providers = {
		claude = {
			endpoint = "https://api.anthropic.com",
			model = "claude-sonnet-4-20250514",
			timeout = 30000, -- Timeout in milliseconds
			disable_tools = true, -- Disable tools to avoid schema validation errors
			extra_request_body = {
				temperature = 0.75,
				max_tokens = 20480,
			},
		},
		-- moonshot = {
		--   endpoint = "https://api.moonshot.ai/v1",
		--   model = "kimi-k2-0711-preview",
		--   timeout = 30000, -- Timeout in milliseconds
		--   extra_request_body = {
		--     temperature = 0.75,
		--     max_tokens = 32768,
		--   },
		-- },
	},
})
