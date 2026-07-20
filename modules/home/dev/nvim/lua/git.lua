-- Git signs, hunks, blame, and quick navigation.
local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
if ok_gitsigns then
	gitsigns.setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
			end

			-- Navigation
			map("n", "]h", function()
				if vim.wo.diff then
					return "]h"
				end
				vim.schedule(gs.next_hunk)
				return "<Ignore>"
			end, "Next git hunk (Gitsigns)")

			map("n", "[h", function()
				if vim.wo.diff then
					return "[h"
				end
				vim.schedule(gs.prev_hunk)
				return "<Ignore>"
			end, "Previous git hunk (Gitsigns)")

			-- Stage / Reset (Mutations -> Action Emojis)
			map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "⚡ Stage hunk (Gitsigns)")
			map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "🔥 Reset hunk (Gitsigns)")
			map("n", "<leader>gA", gs.stage_buffer, "⚡ Stage buffer (Gitsigns)")
			map("n", "<leader>gR", gs.reset_buffer, "🔥 Reset buffer (Gitsigns)")

			-- Views & Displays (No Emojis)
			map("n", "<leader>gp", gs.preview_hunk, "Preview hunk (Gitsigns)")
			map("n", "<leader>gb", function()
				gs.blame_line({ full = true })
			end, "Blame line (Gitsigns)")
			map("n", "<leader>gt", gs.toggle_current_line_blame, "Toggle line blame (Gitsigns)")

			-- Diff (uses <leader>gd — no conflict with snacks picker git_diff)
			map("n", "<leader>gd", gs.diffthis, "Diff buffer (Gitsigns)")
			map("n", "<leader>gD", function()
				gs.diffthis("~")
			end, "Diff vs ~ (Gitsigns)")

			-- Toggle deleted lines
			map("n", "<leader>tx", gs.toggle_deleted, "Toggle deleted lines (Gitsigns)")

			-- Text object: ih = hunk
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select git hunk (Gitsigns)")
		end,
	})
end

-- Neogit: Magit-style keyboard-centric Git interface inside Neovim
local ok_neogit, neogit = pcall(require, "neogit")
if ok_neogit then
	neogit.setup({
		disable_commit_confirmation = true,
		integrations = {
			diffview = true,
		},
	})
	vim.keymap.set("n", "<leader>gn", "<cmd>Neogit<cr>", { desc = "📝 Neogit UI (Neogit)" })
	vim.keymap.set("n", "<leader>gc", "<cmd>Neogit commit<cr>", { desc = "🚀 Commit UI (Neogit)" })
end
