-- Snacks provides fast workflow tools: picker, explorer, notifications, input, scroll, bigfile, and UI helpers.
local ok, snacks = pcall(require, "snacks")
if not ok then
	return
end

-- Safe stub for plugins (like snacks.dashboard) that check require("lazy.stats") when managed by Nix.
package.preload["lazy.stats"] = function()
	return {
		get = function()
			return { count = 50, loaded = 50, startmillis = 0, times = {} }
		end,
	}
end

snacks.setup({
	bigfile = { enabled = true },
	quickfile = { enabled = true },
	image = { enabled = true }, -- Render images in markdown files via Kitty/Sixel
	dashboard = {
		enabled = true,
		on_open = function(buf)
			vim.b[buf].minitrailspace_disable = true
			vim.opt_local.list = false
		end,
		sections = {
			-- Left Pane (Pane 1): Clean Header & Practical Shortcuts
			{ section = "header", pane = 1 },
			{
				section = "keys",
				pane = 1,
				gap = 1,
				padding = 1,
			},
			-- Right Pane (Pane 2): Recent Files, Projects, and Live Git Status
			{
				section = "recent_files",
				pane = 2,
				icon = " ",
				title = "Recent Files",
				limit = 6,
				indent = 2,
				padding = 1,
			},
			{
				section = "projects",
				pane = 2,
				icon = " ",
				title = "Projects",
				limit = 4,
				indent = 2,
				padding = 1,
			},
			{
				section = "terminal",
				cmd = "git -c color.status=always status -sb 2>/dev/null || echo 'Not inside a git repository'",
				pane = 2,
				height = 5,
				padding = 1,
				title = "Git Status",
				icon = " ",
			},
		},
	},
	zen = { enabled = true },
	dim = { enabled = true },
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
end, { desc = "Smart find (Snacks)" })
map("n", "<leader>,", function()
	snacks.picker.buffers()
end, { desc = "Buffers (Snacks)" })
map("n", "<leader>/", function()
	snacks.picker.grep()
end, { desc = "Grep (Snacks)" })
map("n", "<leader>:", function()
	snacks.picker.command_history()
end, { desc = "Command history (Snacks)" })
map("n", "<leader>n", function()
	snacks.picker.notifications()
end, { desc = "Notification history (Snacks)" })

-- Resume last picker — very useful!
map("n", "<leader>fr", function()
	snacks.picker.resume()
end, { desc = "Resume last picker (Snacks)" })

-- Explorer and external file manager.
map("n", "<leader>ee", function()
	snacks.explorer()
end, { desc = "Open Snacks explorer (Snacks)" })
map("n", "<leader>ef", function()
	snacks.explorer({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Explorer at current file (Snacks)" })
map("n", "<leader>ey", function()
	vim.fn.system("tmux split-window -h -l 35% 'yazi " .. vim.fn.shellescape(vim.fn.getcwd()) .. "'")
end, { desc = "Open yazi in tmux (Yazi)" })

-- ══════════════════════════════════════════
-- FIND (Snacks Picker)
-- ══════════════════════════════════════════

map("n", "<leader>ff", function()
	snacks.picker.files()
end, { desc = "Find files (Snacks)" })
map("n", "<leader>fg", function()
	snacks.picker.git_files()
end, { desc = "Find git files (Snacks)" })
map("n", "<leader>fb", function()
	snacks.picker.buffers()
end, { desc = "Find buffers (Snacks)" })
map("n", "<leader>fh", function()
	snacks.picker.help()
end, { desc = "Find help (Snacks)" })
map("n", "<leader>fk", function()
	snacks.picker.keymaps()
end, { desc = "Find keymaps (Snacks)" })
map("n", "<leader>fc", function()
	snacks.picker.commands()
end, { desc = "Find commands (Snacks)" })
map("n", "<leader>fp", function()
	snacks.picker.projects()
end, { desc = "Find projects (Snacks)" })
map("n", "<leader>fm", function()
	snacks.picker.man()
end, { desc = "Find man pages (Snacks)" })
map("n", "<leader>fa", function()
	snacks.picker.autocmds()
end, { desc = "Find autocmds (Snacks)" })
map("n", "<leader>fu", function()
	snacks.picker.undo()
end, { desc = "Undo history (Snacks)" })
map("n", "<leader>fj", function()
	snacks.picker.jumps()
end, { desc = "Jump list (Snacks)" })
map("n", "<leader>fq", function()
	snacks.picker.qflist()
end, { desc = "Quickfix list (Snacks)" })
map("n", "<leader>fR", function()
	snacks.picker.registers()
end, { desc = "Registers (Snacks)" })
map("n", "<leader>fH", function()
	snacks.picker.highlights()
end, { desc = "Highlights (Snacks)" })
map("n", "<leader>fC", function()
	snacks.picker.colorschemes()
end, { desc = "Colorschemes (Snacks)" })
map("n", "<leader>fI", function()
	snacks.picker.icons()
end, { desc = "Find icons & emojis (Snacks)" })
map("n", "<leader>ft", function()
	snacks.picker.todo_comments()
end, { desc = "Find TODO/FIXME comments (Snacks)" })
map("n", "<leader>fl", function()
	snacks.picker.lines()
end, { desc = "Find current buffer lines (Snacks)" })

-- ══════════════════════════════════════════
-- SEARCH (Snacks Picker)
-- ══════════════════════════════════════════

map("n", "<leader>fs", function()
	snacks.picker.lsp_symbols()
end, { desc = "Document symbols (Snacks)" })
map("n", "<leader>fS", function()
	snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols (Snacks)" })
map("n", "<leader>fw", function()
	snacks.picker.grep_word()
end, { desc = "Find word under cursor (Snacks)" })
map("v", "<leader>fw", function()
	snacks.picker.grep_word()
end, { desc = "Find selected text (Snacks)" })
map("n", "<leader>fd", function()
	snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics (Snacks)" })
map("n", "<leader>fD", function()
	snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics (Snacks)" })

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

map("n", "<leader>gB", function()
	snacks.picker.git_branches()
end, { desc = "Git branches" })
map("n", "<leader>gl", function()
	snacks.picker.git_log()
end, { desc = "Git log" })
map("n", "<leader>go", function()
	snacks.gitbrowse()
end, { desc = "Open in browser (Snacks)" })

-- Git (Snacks native)
-- Blame is handled by gitsigns (<leader>gb) — no need for snacks blame

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
