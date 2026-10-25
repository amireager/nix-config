-- UX Enhancements: todo-comments, trouble, diffview

-- ── TODO COMMENTS ──
local ok_todo, todo = pcall(require, "todo-comments")
if ok_todo then
	todo.setup({
		signs = true,
		sign_priority = 8,
		-- keywords/icons: the plugin defaults are used. This file used to repeat them
		-- with the Nerd Font glyphs missing, so every sign was blank.
	})

	-- Under <leader>x (Trouble), not <leader>f (Snacks pickers). Both files
	-- bound <leader>ft and ux.lua loads last, so it silently won and
	-- snacks.picker.todo_comments() was unreachable. They are different tools
	-- worth keeping apart: the picker fuzzy-finds one TODO, Trouble lists all
	-- of them in a pane you work through.
	--
	-- <leader>fT called :TodoTelescope and is gone: telescope is not installed
	-- here, so the key only ever raised "not an editor command".
	vim.keymap.set("n", "<leader>xt", "<cmd>TodoTrouble<cr>", { desc = "TODO list (Trouble)" })
end

-- ── TROUBLE (diagnostics list) ──
local ok_trouble, trouble = pcall(require, "trouble")
if ok_trouble then
	trouble.setup({
		auto_close = false,
		auto_open = false,
		auto_preview = true,
		auto_refresh = true,
		focus = false,
		follow = true,
		indent_guides = true,
		max_items = 200,
		multiline = true,
		severity = nil,
		cycle_results = true,
	})

	-- Keymaps
	vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
	vim.keymap.set(
		"n",
		"<leader>xX",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		{ desc = "Buffer diagnostics (Trouble)" }
	)
	vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
	vim.keymap.set("n", "<leader>xl", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references (Trouble)" })
	vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list (Trouble)" })
	vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list (Trouble)" })
end

-- ── DIFFVIEW (git diff view) ──
local ok_diffview, diffview = pcall(require, "diffview")
if ok_diffview then
	diffview.setup({
		diff_binaries = false,
		enhanced_diff_hl = false,
		git_cmd = { "git" },
		use_icons = true,
		show_help_hints = true,
		watch_index = true,
	})

	-- Keymaps
	vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<cr>", { desc = "Diff view open (Diffview)" })
	vim.keymap.set("n", "<leader>gV", "<cmd>DiffviewClose<cr>", { desc = "Diff view close (Diffview)" })
	vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory<cr>", { desc = "Project history (Diffview)" })
	vim.keymap.set("n", "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", { desc = "File history (Diffview)" })
end
