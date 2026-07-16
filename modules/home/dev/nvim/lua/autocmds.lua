-- Small automations that improve editing without adding heavy plugins.
local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ timeout = 120 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  desc = "Restore cursor position",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "man", "qf", "checkhealth", "lspinfo" },
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true, desc = "Close window" })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  desc = "Remove trailing whitespace before save",
  callback = function()
    local save = vim.fn.winsaveview()
    pcall(function()
      vim.cmd([[%s/\s\+$//e]])
    end)
    vim.fn.winrestview(save)
  end,
})
