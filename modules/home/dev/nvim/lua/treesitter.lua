-- Treesitter: highlighting, indentation, folds and structural text objects.
--
-- nvim-treesitter is on its `main` branch. That rewrite removed
-- `require("nvim-treesitter.configs").setup({ highlight = ... })`: Neovim itself
-- does the highlighting, and the plugin only supplies parsers and queries — here
-- pre-built by Nix (see default.nix). Nothing is downloaded or compiled at
-- runtime, so the `tree-sitter` CLI that `:checkhealth nvim-treesitter` asks for
-- is not needed, and `:TSInstall` must not be used (parsers it would drop into
-- ~/.local/share/nvim/site would shadow the Nix ones and can mismatch queries).
--
-- The old setup call silently failed (it was behind a pcall), so only Lua,
-- Markdown and the first file given on the command line were highlighted by
-- Treesitter, and none of the text objects below existed.

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
	desc = "Treesitter highlighting and indent when a parser exists for the filetype",
	callback = function(args)
		local buf = args.buf
		local lang = vim.treesitter.language.get_lang(args.match)
		if not (lang and vim.treesitter.language.add(lang)) then
			return -- no parser for this filetype: keep Vim's regex syntax
		end
		-- Lua, Markdown, help and query start it from their own ftplugin, and
		-- snacks.quickfile starts it for the file named on the command line.
		if not vim.b[buf].ts_highlight and not pcall(vim.treesitter.start, buf, lang) then
			return
		end
		-- Indent is set either way, so the first buffer and later ones behave alike.
		if vim.treesitter.query.get(lang, "indents") then
			vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
		-- Folds follow the syntax tree (zc/zo/za, zR/zM). Nothing starts folded:
		-- 'foldlevelstart' is 99 in options.lua.
		if vim.treesitter.query.get(lang, "folds") then
			vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.wo[0][0].foldmethod = "expr"
		end
	end,
})

-- ── Text objects ────────────────────────────────────────────────────────────
-- Operate on syntax nodes instead of lines: `daf` deletes a whole function,
-- `vic` selects a class body, `]f` jumps to the next function.
local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
if not ok then
	return
end

textobjects.setup({
	select = {
		lookahead = true, -- jump forward to the next object if not inside one
		selection_modes = {
			["@function.outer"] = "V",
			["@class.outer"] = "V",
		},
	},
	move = { set_jumps = true }, -- so <C-o> works after a structural jump
})

local function select(query)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
	end
end

for _, o in ipairs({
	{ "af", "@function.outer", "a function" },
	{ "if", "@function.inner", "inner function" },
	{ "ac", "@class.outer", "a class" },
	{ "ic", "@class.inner", "inner class" },
	{ "aa", "@parameter.outer", "an argument" },
	{ "ia", "@parameter.inner", "inner argument" },
	{ "ai", "@conditional.outer", "a conditional" },
	{ "ii", "@conditional.inner", "inner conditional" },
	{ "al", "@loop.outer", "a loop" },
	{ "il", "@loop.inner", "inner loop" },
	{ "a/", "@comment.outer", "a comment" },
}) do
	vim.keymap.set({ "x", "o" }, o[1], select(o[2]), { desc = o[3] })
end

local function move(fn, query)
	return function()
		require("nvim-treesitter-textobjects.move")[fn](query, "textobjects")
	end
end

-- ]c / [c are mini.bracketed's comment motions, so classes get ]k / [k rather
-- than silently stealing them.
for _, m in ipairs({
	{ "]f", "goto_next_start", "@function.outer", "Next function" },
	{ "]k", "goto_next_start", "@class.outer", "Next class" },
	{ "]a", "goto_next_start", "@parameter.inner", "Next argument" },
	{ "[f", "goto_previous_start", "@function.outer", "Previous function" },
	{ "[k", "goto_previous_start", "@class.outer", "Previous class" },
	{ "[a", "goto_previous_start", "@parameter.inner", "Previous argument" },
	{ "]F", "goto_next_end", "@function.outer", "Next function end" },
	{ "]K", "goto_next_end", "@class.outer", "Next class end" },
	{ "[F", "goto_previous_end", "@function.outer", "Previous function end" },
	{ "[K", "goto_previous_end", "@class.outer", "Previous class end" },
}) do
	vim.keymap.set({ "n", "x", "o" }, m[1], move(m[2], m[3]), { desc = m[4] })
end

-- Swap an argument with its neighbour without touching the commas. <leader>c,
-- not <leader>n: snacks.lua binds <leader>n on its own for the notification
-- history, and a single-key mapping fires immediately — so <leader>na could
-- never be typed. A swap is a code edit, which is what <leader>c already means.
vim.keymap.set("n", "<leader>cs", function()
	require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
end, { desc = "Swap argument with next" })
vim.keymap.set("n", "<leader>cS", function()
	require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
end, { desc = "Swap argument with previous" })
