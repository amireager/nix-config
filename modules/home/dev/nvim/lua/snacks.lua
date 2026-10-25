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
				-- Only inside a repository (no shell is spawned elsewhere), and
				-- uncached: the default ttl of one hour showed an hour-old status.
				enabled = function()
					return Snacks.git.get_root() ~= nil
				end,
				ttl = 0,
				cmd = "git -c color.status=always status -sb",
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
		-- Snacks loads libsqlite3 through the dynamic loader *by name*, which cannot
		-- find it on NixOS. default.nix passes the store path; without SQLite the
		-- picker's frecency and history fall back to a flat file.
		db = { sqlite3_path = vim.g.nix_sqlite3_path },
		sources = {
			files = { hidden = true, ignored = false },
			grep = { hidden = true, ignored = false },
		},
		win = {
			input = {
				keys = {
					["<a-i>"] = { "toggle_ignored", mode = { "i", "n" }, desc = "Toggle Gitignored (.gitignore)" },
					["<a-h>"] = { "toggle_hidden", mode = { "i", "n" }, desc = "Toggle Hidden files" },
				},
			},
		},
	},
	explorer = { enabled = true },
	indent = {
		enabled = true,
		priority = 1,
		char = "│",
		only_scope = false,
		only_current = false,
		hl = {
			"SnacksIndent1",
			"SnacksIndent2",
			"SnacksIndent3",
			"SnacksIndent4",
			"SnacksIndent5",
			"SnacksIndent6",
			"SnacksIndent7",
			"SnacksIndent8",
		},
	},
	scope = {
		enabled = true,
		priority = 200,
		char = "│",
		underline = false,
		only_current = false,
		hl = {
			"SnacksIndent1",
			"SnacksIndent2",
			"SnacksIndent3",
			"SnacksIndent4",
			"SnacksIndent5",
			"SnacksIndent6",
			"SnacksIndent7",
			"SnacksIndent8",
		},
		animate = {
			enabled = false,
		},
	},
	scroll = { enabled = true, animate = { duration = { step = 12, total = 120 } } },
	statuscolumn = { enabled = true },
	words = { enabled = true },
})

-- Neovim 0.12 overlays "[Process exited N]" on every finished terminal, which
-- landed in the middle of the dashboard's git-status pane. Remove it there only;
-- ordinary :terminal buffers keep it.
vim.api.nvim_create_autocmd("TermClose", {
	desc = "No exit-status overlay inside the dashboard",
	callback = function(args)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].filetype == "snacks_dashboard" then
				local ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")
				vim.api.nvim_buf_clear_namespace(args.buf, ns, 0, -1)
			end
		end)
	end,
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
-- FOCUS & ZEN MODES (Snacks)
-- ══════════════════════════════════════════
map("n", "<leader>uz", function()
	snacks.toggle.dim():toggle()
end, { desc = "Toggle focus/dim mode (Snacks)" })

map("n", "<leader>uZ", function()
	snacks.toggle.zen():toggle()
end, { desc = "Toggle zen mode (Snacks)" })

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
	local cwd = vim.fn.getcwd()
	if vim.env.TMUX and vim.env.TMUX ~= "" then
		vim.fn.system({ "tmux", "split-window", "-h", "-l", "35%", "yazi " .. vim.fn.shellescape(cwd) })
	else
		-- Outside tmux the old mapping did nothing at all.
		snacks.terminal({ "yazi", cwd }, { cwd = cwd, win = { position = "float" } })
	end
end, { desc = "Open yazi (tmux split, or float outside tmux)" })

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
-- nowait: Neovim 0.11+ also defines grr/gra/grn/gri/grt, which makes `gr` a
-- prefix, and without it every `gr` waited out 'timeoutlen' (350 ms). The
-- built-in gr* mappings are covered by <leader>l* here.
map("n", "gr", function()
	snacks.picker.lsp_references()
end, { nowait = true, desc = "LSP references (Snacks)" })
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
-- SCRATCH, REFERENCES, INLAY HINTS (Snacks)
-- ══════════════════════════════════════════

-- A persistent scratch buffer per project (notes, a throwaway query, a pasted log).
map("n", "<leader>.", function()
	snacks.scratch()
end, { desc = "Scratch buffer (Snacks)" })

-- ]r / [r jump between the references of the word under the cursor (an LSP that
-- supports documentHighlight must be attached; Snacks.words asks it on
-- CursorMoved). ]] and [[ are not used: the Go, Python, Rust, Lua, Markdown and
-- C ftplugins map them buffer-locally for function/section motions.
for key, direction in pairs({ ["]r"] = 1, ["[r"] = -1 }) do
	map("n", key, function()
		if snacks.words.is_enabled() then
			snacks.words.jump(direction * vim.v.count1, true)
		else
			vim.notify("No LSP references in this buffer", vim.log.levels.INFO, { title = "References" })
		end
	end, { desc = direction == 1 and "Next reference (Snacks)" or "Previous reference (Snacks)" })
end

-- Inline type/parameter hints from rust-analyzer, gopls, ts_ls, lua_ls. Off by default.
snacks.toggle.inlay_hints():map("<leader>uh")

-- ══════════════════════════════════════════
-- UI TOGGLES (Snacks)
-- ══════════════════════════════════════════

map("n", "<leader>un", function()
	snacks.notifier.hide()
end, { desc = "Dismiss notifications (Snacks)" })
map("n", "<leader>uN", function()
	snacks.toggle.notifier():toggle()
end, { desc = "Toggle notification popups (Snacks)" })
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
	snacks.toggle.option("conceallevel", { off = 0, on = 2 }):toggle()
end, { desc = "Toggle conceal (Snacks)" })
