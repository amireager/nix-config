-- Small automations that improve editing without adding heavy plugins.
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	desc = "Highlight yanked text",
	callback = function()
		vim.hl.on_yank({ timeout = 120 })
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	desc = "Restore cursor position",
	callback = function(args)
		-- Commit messages and rebase todo files are rewritten every time; an old
		-- cursor line from a previous commit is never what you want.
		local ft = vim.bo[args.buf].filetype
		if ft:match("^git") or ft == "help" or vim.bo[args.buf].buftype ~= "" then
			return
		end
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Files change under Neovim's feet: a coding agent in another terminal, lazygit
-- or a formatter run from a shell. 'autoread' only acts when something calls
-- :checktime. Neovim 0.12 does that on FocusGained by itself, but not when you
-- move to another window or after a terminal job ends, so the buffer kept stale
-- text and the next :write overwrote the change (or asked W12). tmux.nix
-- already sets focus-events, which FocusGained needs inside tmux.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter" }, {
	group = augroup,
	desc = "Reload buffers that changed on disk",
	callback = function()
		if vim.fn.mode() ~= "c" then
			vim.cmd("checktime")
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "help", "man", "qf", "checkhealth" },
	callback = function(event)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true, desc = "Close window" })
	end,
})

-- Trailing whitespace is significant in these: two spaces end a Markdown line
-- with a hard break, and a blank context line of a patch is a single space.
-- Stripping them silently corrupted both on every :write.
local keep_trailing_whitespace = {
	markdown = true,
	diff = true,
	mail = true,
	gitsendemail = true,
}

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	desc = "Remove trailing whitespace before save",
	callback = function(args)
		local bo = vim.bo[args.buf]
		if bo.binary or not bo.modifiable or keep_trailing_whitespace[bo.filetype] then
			return
		end
		local save = vim.fn.winsaveview()
		-- keeppatterns: do not clobber the last search pattern.
		pcall(vim.cmd, [[keeppatterns %s/\s\+$//e]])
		vim.fn.winrestview(save)
	end,
})
