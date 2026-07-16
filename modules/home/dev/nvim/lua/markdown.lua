-- render-markdown.nvim — inline markdown rendering in nvim
local ok, render_markdown = pcall(require, "render-markdown")
if not ok then
	return
end

render_markdown.setup({
	-- Render in normal, visual, and command modes (not insert)
	enabled = true,
	max_file_size = 10.0, -- MB, skip rendering for huge files
	latex = { enabled = false }, -- disable LaTeX rendering (enable if needed)
	-- Heading icons
	heading = {
		sign = false,
		icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
	},
	-- Checkbox rendering
	checkbox = {
		unchecked = { icon = "󰄱 " },
		checked = { icon = "󰱒 " },
		custom = {
			todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
		},
	},
	-- Code block style
	code = {
		sign = false,
		style = "normal",
	},
	-- Bullet list icons
	bullet = {
		icons = { "●", "○", "◆", "◇" },
	},
})

-- Keymaps under <leader>m
vim.keymap.set("n", "<leader>mt", function()
	render_markdown.toggle()
end, { desc = "Toggle markdown render" })

vim.keymap.set("n", "<leader>me", function()
	render_markdown.enable()
end, { desc = "Enable markdown render" })

vim.keymap.set("n", "<leader>md", function()
	render_markdown.disable()
end, { desc = "Disable markdown render" })
