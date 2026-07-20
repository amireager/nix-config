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
		{ "<leader>b", group = " Buffers (bufferline)" },
		{ "<leader>c", group = " Code (LSP)" },
		{ "<leader>d", group = " Debug (DAP) — disabled" },
		{ "<leader>e", group = " Explorer (Snacks)" },
		{ "<leader>f", group = " Find (Snacks)" },
		{ "<leader>g", group = " Git (Gitsigns + Snacks + Diffview)" },
		{ "<leader>l", group = " LSP" },
		{ "<leader>m", group = " Markdown" },
		{ "<leader>r", group = " Run / REPL (Slime)" },
		{ "<leader>t", group = " Tabs / Terminal" },
		{ "<leader>u", group = " UI Toggles (Snacks)" },
		{ "<leader>w", group = " Windows (Native)" },
		{ "<leader>x", group = " Diagnostics (Trouble)" },
	})
end

-- UI toggles — no conflicts with snacks.lua
vim.keymap.set("n", "<leader>ul", function()
	vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative line numbers" })

vim.keymap.set("n", "<leader>uW", function()
	vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle word wrap" })

vim.keymap.set("n", "<leader>uS", function()
	vim.opt.spell = not vim.opt.spell:get()
end, { desc = "Toggle spell check" })
