-- UI plugins: theme setup, per-tab buffer isolation (scope), statusline, bufferline, which-key.

-- 1. Scope setup: isolates buffers per Neovim tab so each new tab has its own clean bufferline!
local ok_scope, scope = pcall(require, "scope")
if ok_scope then
	scope.setup()
end

-- 2. Theme configurations (Nightfox, Catppuccin, Tokyonight)
-- Nightfox setup with exact deep-dark palette requested (#0d131a)
local ok_nf, nightfox = pcall(require, "nightfox")
if ok_nf then
	nightfox.setup({
		palettes = {
			nightfox = {
				bg0 = "#0d131a",
				bg1 = "#141b22",
				bg3 = "#202a36",
			},
		},
		options = {
			transparent = false,
			dim_inactive = false,
		},
	})
end

-- Catppuccin setup
local ok_cat, catppuccin = pcall(require, "catppuccin")
if ok_cat then
	catppuccin.setup({
		flavour = "mocha",
		transparent_background = false,
		term_colors = true,
		integrations = {
			blink_cmp = true,
			gitsigns = true,
			treesitter = true,
			native_lsp = { enabled = true },
			snacks = true,
		},
	})
end

-- Tokyonight setup
local ok_tn, tokyonight = pcall(require, "tokyonight")
if ok_tn then
	tokyonight.setup({
		style = "storm",
		transparent = false,
		terminal_colors = true,
	})
end

-- Set default active colorscheme (Nightfox custom #0d131a by default, switch live with <leader>fC)
vim.cmd.colorscheme("nightfox")

-- Snacks Indent & Scope rainbow levels (Catppuccin / Nightfox harmonious palette)
local function setup_indent_highlights()
	local indent_colors = {
		SnacksIndent1 = { fg = "#89b4fa" }, -- Blue
		SnacksIndent2 = { fg = "#a6e3a1" }, -- Green
		SnacksIndent3 = { fg = "#f9e2af" }, -- Yellow
		SnacksIndent4 = { fg = "#fab387" }, -- Peach
		SnacksIndent5 = { fg = "#f38ba8" }, -- Red
		SnacksIndent6 = { fg = "#cba6f7" }, -- Mauve
		SnacksIndent7 = { fg = "#94e2d5" }, -- Teal
		SnacksIndent8 = { fg = "#74c7ec" }, -- Sapphire
	}
	for group, spec in pairs(indent_colors) do
		vim.api.nvim_set_hl(0, group, spec)
	end
end

setup_indent_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = setup_indent_highlights,
})

local function lsp_clients()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return "No LSP"
	end
	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end
	return table.concat(names, ",")
end

local ok_lualine, lualine = pcall(require, "lualine")
if ok_lualine then
	lualine.setup({
		options = {
			theme = "catppuccin",
			globalstatus = true,
			component_separators = "",
			section_separators = { left = "", right = "" },
			disabled_filetypes = { statusline = { "dashboard" } },
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff" },
			lualine_c = {
				{ "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
			},
			lualine_x = {
				"diagnostics",
				{ lsp_clients, icon = " " },
				"encoding",
				"filetype",
			},
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
	})
end

local ok_bufferline, bufferline = pcall(require, "bufferline")
if ok_bufferline then
	bufferline.setup({
		options = {
			mode = "buffers",
			diagnostics = "nvim_lsp",
			separator_style = "thin",
			show_buffer_close_icons = false,
			show_close_icon = false,
			always_show_bufferline = true,
			tab_size = 18,
			max_name_length = 24,
			max_prefix_length = 12,
			numbers = "ordinal",
			offsets = {
				{ filetype = "snacks_layout_box", text = "Explorer", text_align = "center" },
			},
		},
	})
end

local ok_which, which_key = pcall(require, "which-key")
if ok_which then
	which_key.setup({
		preset = "modern",
		delay = 250,
	})

	which_key.add({
		{ "<leader>a", group = "🤖 AI (CodeCompanion)" },
		{ "<leader>b", group = "📑 Buffers (Bufferline)" },
		{ "<leader>c", group = "⚡ Code & Rename (LSP)" },
		{ "<leader>d", group = "🐞 Debug (DAP)" },
		{ "<leader>e", group = " Explorer (Snacks)" },
		{ "<leader>f", group = "🔍 Find Pickers (Snacks)" },
		{ "<leader>g", group = " Git & Undo (Neogit + Gitsigns)" },
		{ "<leader>l", group = "🧠 LSP & Diagnostics" },
		{ "<leader>m", group = "📝 Markdown Tools" },
		{ "<leader>r", group = "▶️ Run / REPL (Slime)" },
		{ "<leader>t", group = "💻 Tabs & Terminal" },
		{ "<leader>u", group = "🎨 UI & Format Toggles" },
		{ "<leader>w", group = "🪟 Windows (Native)" },
		{ "<leader>x", group = "🚨 Diagnostics (Trouble)" },
	})
end

-- UI toggles — consistent <leader>u palette
vim.keymap.set("n", "<leader>ul", function()
	vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative line numbers" })

vim.keymap.set("n", "<leader>uW", function()
	vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle word wrap" })

vim.keymap.set("n", "<leader>uS", function()
	vim.opt.spell = not vim.opt.spell:get()
end, { desc = "Toggle spell check" })

vim.keymap.set("n", "<leader>um", function()
	local ok, rm = pcall(require, "render-markdown")
	if ok then
		rm.toggle()
	end
end, { desc = "Toggle markdown render (RenderMarkdown)" })

vim.keymap.set("n", "<leader>ub", function()
	local ok, gs = pcall(require, "gitsigns")
	if ok then
		gs.toggle_current_line_blame()
	end
end, { desc = "Toggle git line blame (Gitsigns)" })

vim.keymap.set("n", "<leader>ug", function()
	local ok, gs = pcall(require, "gitsigns")
	if ok then
		gs.toggle_deleted()
	end
end, { desc = "Toggle git deleted lines (Gitsigns)" })
