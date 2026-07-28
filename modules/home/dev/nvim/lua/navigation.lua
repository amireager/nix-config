-- ============================================================================
-- NAVIGATION — jumping, structural motion, and screen-relative movement
-- ============================================================================
-- Loaded after productivity.lua so it can override mappings that mini.nvim
-- would otherwise own.
-- ============================================================================

-- ── flash.nvim ──────────────────────────────────────────────────────────────
-- Replaces mini.jump2d. The difference is when the query is asked for:
-- mini.jump2d immediately labels every word start in the window, so `s` filled
-- the screen with labels and there was nothing to type. flash asks for the
-- characters first and narrows the labels as you type, so two keystrokes
-- usually leave a single target.
local ok_flash, flash = pcall(require, "flash")
if ok_flash then
	flash.setup({
		labels = "asdfghjklqwertyuiopzxcvbnm",

		search = {
			multi_window = true,
			forward = true,
			wrap = true,
			-- "exact" rather than "fuzzy": with fuzzy, the label positions keep
			-- moving while you type, which defeats muscle memory.
			mode = "exact",
			incremental = true,
		},

		jump = {
			jumplist = true, -- so <C-o> comes back
			pos = "start",
			history = false,
			register = false,
			nohlsearch = true,
			autojump = false, -- never jump without confirming, even on one match
		},

		label = {
			uppercase = false,
			after = false,
			before = true, -- label sits before the match, so it never hides it
			style = "overlay",
			reuse = "lowercase",
			distance = true, -- nearest matches get the easiest labels
			min_pattern_length = 0,
			rainbow = { enabled = false },
		},

		highlight = {
			backdrop = true, -- dim everything that is not a candidate
			matches = true,
		},

		modes = {
			-- Make `f`/`t` work across lines and stay repeatable with `;`/`,`.
			char = {
				enabled = true,
				jump_labels = false, -- plain f/t behaviour, just multi-line
				multi_line = true,
				keys = { "f", "F", "t", "T", ";", "," },
			},
			-- `/` and `?` get labels too, so search doubles as a jump.
			search = {
				enabled = true,
			},
		},
	})

	local map = vim.keymap.set

	map({ "n", "x", "o" }, "s", function()
		require("flash").jump()
	end, { desc = "Flash jump" })

	map({ "n", "x", "o" }, "S", function()
		require("flash").treesitter()
	end, { desc = "Flash treesitter select" })

	-- In operator-pending mode: `yr` then a label yanks a remote text object
	-- without moving the cursor.
	map("o", "r", function()
		require("flash").remote()
	end, { desc = "Remote flash" })

	map({ "o", "x" }, "R", function()
		require("flash").treesitter_search()
	end, { desc = "Treesitter search" })

	-- Toggle flash labels inside a normal `/` search.
	map("c", "<C-s>", function()
		require("flash").toggle()
	end, { desc = "Toggle flash in search" })
end

-- ── Screen-relative motion ──────────────────────────────────────────────────
-- H and L were bound to buffer switching, which shadowed the built-in motions
-- (H = top of screen, L = bottom). That is why only M appeared to work: it was
-- the one still doing its default job.
--
-- Buffer switching moves to <Tab>/<S-Tab>, which is what most editors use, and
-- H/M/L go back to being motions.
local map = vim.keymap.set

map("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

-- scrolloff keeps the cursor away from the window edge, so a plain H or L
-- stops that many lines short of the real top/bottom. The offset is read at
-- call time rather than hard-coded, so changing scrolloff needs no edit here.
map({ "n", "x" }, "H", function()
	local off = vim.o.scrolloff
	vim.cmd("normal! H")
	if off > 0 and vim.fn.line(".") > vim.fn.line("w0") then
		vim.cmd("normal! " .. off .. "k")
	end
end, { desc = "Top of screen" })

map({ "n", "x" }, "L", function()
	local off = vim.o.scrolloff
	vim.cmd("normal! L")
	if off > 0 and vim.fn.line(".") < vim.fn.line("w$") then
		vim.cmd("normal! " .. off .. "j")
	end
end, { desc = "Bottom of screen" })

-- M is left alone — it was never shadowed and needs no correction.

-- ── treesitter-context ──────────────────────────────────────────────────────
-- Sticky header showing the enclosing function/class when its opening line has
-- scrolled off. Most useful in long files, which is exactly when it is hard to
-- remember where you are.
local ok_ctx, ctx = pcall(require, "treesitter-context")
if ok_ctx then
	ctx.setup({
		enable = true,
		max_lines = 3, -- more than this eats the window
		min_window_height = 20, -- pointless in a small split
		line_numbers = true,
		multiline_threshold = 1, -- collapse multi-line signatures to one line
		trim_scope = "outer",
		mode = "cursor",
		separator = "─",
		zindex = 20,
	})

	vim.keymap.set("n", "[x", function()
		require("treesitter-context").go_to_context(vim.v.count1)
	end, { desc = "Jump to context (function header)" })

	vim.keymap.set("n", "<leader>ux", function()
		require("treesitter-context").toggle()
	end, { desc = "Toggle treesitter context" })
end

-- ── treesitter-textobjects ──────────────────────────────────────────────────
-- Operate on syntax nodes instead of lines: `daf` deletes a whole function,
-- `vic` selects a class body, `]f` jumps to the next function.
-- NOTE: this is the only nvim-treesitter.configs.setup() call in the config.
-- Grammars come pre-built from Nix, so highlighting already worked without
-- one. Because setup() replaces the whole configuration rather than merging
-- into it, highlight and indent have to be stated here explicitly — omitting
-- them would silently turn syntax highlighting off.
local ok_ts, ts = pcall(require, "nvim-treesitter.configs")
if ok_ts then
	ts.setup({
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
		indent = { enable = true },

		textobjects = {
			select = {
				enable = true,
				lookahead = true, -- jump forward to the next object if not inside one
				keymaps = {
					["af"] = { query = "@function.outer", desc = "a function" },
					["if"] = { query = "@function.inner", desc = "inner function" },
					["ac"] = { query = "@class.outer", desc = "a class" },
					["ic"] = { query = "@class.inner", desc = "inner class" },
					["aa"] = { query = "@parameter.outer", desc = "an argument" },
					["ia"] = { query = "@parameter.inner", desc = "inner argument" },
					["ai"] = { query = "@conditional.outer", desc = "a conditional" },
					["ii"] = { query = "@conditional.inner", desc = "inner conditional" },
					["al"] = { query = "@loop.outer", desc = "a loop" },
					["il"] = { query = "@loop.inner", desc = "inner loop" },
					["a/"] = { query = "@comment.outer", desc = "a comment" },
				},
				selection_modes = {
					["@function.outer"] = "V",
					["@class.outer"] = "V",
				},
			},

			move = {
				enable = true,
				set_jumps = true, -- so <C-o> works after a structural jump
				goto_next_start = {
					["]f"] = { query = "@function.outer", desc = "Next function" },
					-- ]c / [c are mini.bracketed's comment motions, so classes
					-- get ]k / [k rather than silently stealing them.
					["]k"] = { query = "@class.outer", desc = "Next class" },
					["]a"] = { query = "@parameter.inner", desc = "Next argument" },
				},
				goto_previous_start = {
					["[f"] = { query = "@function.outer", desc = "Previous function" },
					["[k"] = { query = "@class.outer", desc = "Previous class" },
					["[a"] = { query = "@parameter.inner", desc = "Previous argument" },
				},
				goto_next_end = {
					["]F"] = { query = "@function.outer", desc = "Next function end" },
					["]K"] = { query = "@class.outer", desc = "Next class end" },
				},
				goto_previous_end = {
					["[F"] = { query = "@function.outer", desc = "Previous function end" },
					["[K"] = { query = "@class.outer", desc = "Previous class end" },
				},
			},

			-- Swap an argument with its neighbour without touching the commas.
			swap = {
				enable = true,
				swap_next = { ["<leader>na"] = "@parameter.inner" },
				swap_previous = { ["<leader>pa"] = "@parameter.inner" },
			},
		},
	})
end

-- ── lazydev ─────────────────────────────────────────────────────────────────
-- Loads Neovim API types into LuaLS on demand, so `vim.` completes while
-- editing this configuration. Only the modules actually required by open files
-- are loaded, which is why it is fast.
local ok_lazydev, lazydev = pcall(require, "lazydev")
if ok_lazydev then
	lazydev.setup({
		library = {
			-- vim.uv types only when the file mentions them
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		},
		integrations = {
			lspconfig = true,
			cmp = false, -- blink is wired as a provider in completion.lua instead
		},
	})
end
