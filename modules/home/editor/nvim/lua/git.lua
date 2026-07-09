-- Git signs, hunks, blame, and quick navigation.
local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
if ok_gitsigns then
	gitsigns.setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
			end

			map("n", "]h", function()
				if vim.wo.diff then
					return "]h"
				end
				vim.schedule(gs.next_hunk)
				return "<Ignore>"
			end, "Next git hunk")

			map("n", "[h", function()
				if vim.wo.diff then
					return "[h"
				end
				vim.schedule(gs.prev_hunk)
				return "<Ignore>"
			end, "Previous git hunk")

			map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
			map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
			map("n", "<leader>gA", gs.stage_buffer, "Stage buffer")
			map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
			map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
			map("n", "<leader>gB", function()
				gs.blame_line({ full = true })
			end, "Blame line")
			map("n", "<leader>gt", gs.toggle_current_line_blame, "Toggle line blame")
			map("n", "<leader>gd", gs.diffthis, "Diff this file")
			map("n", "<leader>gD", function()
				gs.diffthis("~")
			end, "Diff this file ~")
			map("n", "<leader>tx", gs.toggle_deleted, "Toggle deleted lines")
		end,
	})
end
