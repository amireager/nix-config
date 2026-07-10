-- Snacks provides fast workflow tools: picker, explorer, notifications, input, scroll, bigfile, and UI helpers.
local ok, snacks = pcall(require, "snacks")
if not ok then
	return
end

snacks.setup({
	bigfile = { enabled = true },
	quickfile = { enabled = true },
	dashboard = { enabled = false },
	input = { enabled = true },
	notifier = { enabled = true, timeout = 2500 },
	picker = {
		enabled = true,
		sources = {
			files = { hidden = true, ignored = false },
			grep = { hidden = true, ignored = false },
		},
	},
	explorer = { enabled = true },
	indent = { enabled = true },
	scope = { enabled = true },
	scroll = { enabled = true, animate = { duration = { step = 12, total = 120 } } },
	statuscolumn = { enabled = true },
	words = { enabled = true },
})

local map = vim.keymap.set

-- ══════════════════════════════════════════
-- LAZYGIT (Snacks)
-- ══════════════════════════════════════════
map("n", "<leader>gg", function()
	snacks.lazygit()
end, { desc = "Lazygit (Snacks)" })
map("n", "<leader>gF", function()
	snacks.lazygit.log_file()
end, { desc = "Git log current file (Snacks)" })
map("n", "<leader>gL", function()
	snacks.lazygit.log()
end, { desc = "Git log (Snacks)" })

-- ══════════════════════════════════════════
-- TERMINAL (Snacks)
-- ══════════════════════════════════════════
map("n", "<leader>tt", function()
	snacks.terminal()
end, { desc = "Terminal toggle (Snacks)" })
map("n", "<leader>tf", function()
	snacks.terminal("fish", { win = { position = "bottom", height = 0.3 } })
end, { desc = "Terminal bottom float (Snacks)" })

-- ══════════════════════════════════════════
-- ZEN MODE (Snacks)
-- ══════════════════════════════════════════
map("n", "<leader>uz", function()
	snacks.zen()
end, { desc = "Zen mode toggle (Snacks)" })

-- ══════════════════════════════════════════
-- TOP-LEVEL FAST ACTIONS (Snacks)
-- ══════════════════════════════════════════

map("n", "<leader><space>", function()
	snacks.picker.smart()
end, { desc = "Smart find" })
map("n", "<leader>,", function()
	snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>/", function()
	snacks.picker.grep()
end, { desc = "Grep" })
map("n", "<leader>:", function()
	snacks.picker.command_history()
end, { desc = "Command history" })
map("n", "<leader>n", function()
	snacks.picker.notifications()
end, { desc = "Notification history" })

-- Resume last picker — very useful!
map("n", "<leader>fr", function()
	snacks.picker.resume()
end, { desc = "Resume last picker" })

-- Explorer and external file manager.
map("n", "<leader>ee", function()
	snacks.explorer()
end, { desc = "Open Snacks explorer" })
map("n", "<leader>ef", function()
	snacks.explorer({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Explorer at current file" })
map("n", "<leader>ey", function()
	vim.fn.system("tmux split-window -h -l 35% 'yazi " .. vim.fn.shellescape(vim.fn.getcwd()) .. "'")
end, { desc = "Open yazi in tmux" })

-- ══════════════════════════════════════════
-- FIND (Snacks Picker)
-- ══════════════════════════════════════════

map("n", "<leader>ff", function()
	snacks.picker.files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
	snacks.picker.git_files()
end, { desc = "Find git files" })
map("n", "<leader>fb", function()
	snacks.picker.buffers()
end, { desc = "Find buffers" })
map("n", "<leader>fh", function()
	snacks.picker.help()
end, { desc = "Find help" })
map("n", "<leader>fk", function()
	snacks.picker.keymaps()
end, { desc = "Find keymaps" })
map("n", "<leader>fc", function()
	snacks.picker.commands()
end, { desc = "Find commands" })
map("n", "<leader>fp", function()
	snacks.picker.projects()
end, { desc = "Find projects" })
map("n", "<leader>fm", function()
	snacks.picker.man()
end, { desc = "Find man pages" })
map("n", "<leader>fa", function()
	snacks.picker.autocmds()
end, { desc = "Find autocmds" })
map("n", "<leader>fu", function()
	snacks.picker.undo()
end, { desc = "Undo history" })
map("n", "<leader>fj", function()
	snacks.picker.jumps()
end, { desc = "Jump list" })
map("n", "<leader>fq", function()
	snacks.picker.qflist()
end, { desc = "Quickfix list" })
map("n", "<leader>fR", function()
	snacks.picker.registers()
end, { desc = "Registers" })
map("n", "<leader>fH", function()
	snacks.picker.highlights()
end, { desc = "Highlights" })
map("n", "<leader>fC", function()
	snacks.picker.colorschemes()
end, { desc = "Colorschemes" })

-- ══════════════════════════════════════════
-- SEARCH (Snacks Picker)
-- ══════════════════════════════════════════

map("n", "<leader>fs", function()
	snacks.picker.lsp_symbols()
end, { desc = "Document symbols" })
map("n", "<leader>fS", function()
	snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols" })
map("n", "<leader>fw", function()
	snacks.picker.grep_word()
end, { desc = "Find word under cursor" })
map("v", "<leader>fw", function()
	snacks.picker.grep_word()
end, { desc = "Find selected text" })
map("n", "<leader>fd", function()
	snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics" })
map("n", "<leader>fD", function()
	snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })

-- LSP pickers via Snacks
map("n", "gr", function()
	snacks.picker.lsp_references()
end, { desc = "LSP references (Snacks)" })
map("n", "gd", function()
	snacks.picker.lsp_definitions()
end, { desc = "LSP definitions (Snacks)" })
map("n", "gI", function()
	snacks.picker.lsp_implementations()
end, { desc = "LSP implementations (Snacks)" })
map("n", "gy", function()
	snacks.picker.lsp_type_definitions()
end, { desc = "LSP type definitions (Snacks)" })

-- ══════════════════════════════════════════
-- GIT PICKERS (Snacks)
-- ══════════════════════════════════════════

map("n", "<leader>gb", function()
	snacks.picker.git_branches()
end, { desc = "Git branches" })
map("n", "<leader>gl", function()
	snacks.picker.git_log()
end, { desc = "Git log" })
map("n", "<leader>go", function()
	snacks.gitbrowse()
end, { desc = "Open in browser (Snacks)" })

-- Git (Snacks native)
map("n", "<leader>gB", function()
	snacks.git.blame_line()
end, { desc = "Blame line (Snacks)" })

-- ══════════════════════════════════════════
-- RENAME (Snacks)
-- ══════════════════════════════════════════

map("n", "<leader>cR", function()
	snacks.rename.rename_file()
end, { desc = "Rename file (Snacks)" })

-- ══════════════════════════════════════════
-- UI TOGGLES (Snacks)
-- ══════════════════════════════════════════

map("n", "<leader>un", function()
	snacks.notifier.hide()
end, { desc = "Dismiss notifications (Snacks)" })
map("n", "<leader>ui", function()
	snacks.toggle.indent():toggle()
end, { desc = "Toggle indent guides (Snacks)" })
map("n", "<leader>us", function()
	snacks.toggle.scroll():toggle()
end, { desc = "Toggle smooth scroll (Snacks)" })
map("n", "<leader>uw", function()
	snacks.toggle.words():toggle()
end, { desc = "Toggle word highlight (Snacks)" })
map("n", "<leader>ud", function()
	snacks.toggle.diagnostics():toggle()
end, { desc = "Toggle diagnostics (Snacks)" })
map("n", "<leader>uc", function()
	snacks.toggle("conceallevel", { off = 0, on = 2 }):toggle()
end, { desc = "Toggle conceal (Snacks)" })
