-- Python cell execution through tmux + IPython via vim-slime.
-- Supported cell markers:
--   # %%
--   #%%
--   # <codecell>

vim.g.slime_target = "tmux"
vim.g.slime_no_mappings = 1
vim.g.slime_bracketed_paste = 1
vim.g.slime_default_config = {
  socket_name = "default",
  target_pane = "{right-of}",
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Run / REPL" })
end

local function in_tmux()
  return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

local function send_to_slime(text)
  if text == nil or text == "" then
    notify("Nothing to send", vim.log.levels.WARN)
    return
  end

  if not in_tmux() then
    notify("Start Neovim inside tmux first", vim.log.levels.WARN)
  end

  local ok = pcall(function()
    vim.fn["slime#send"](text .. "\n")
  end)

  if not ok then
    notify("vim-slime is not ready. Open a tmux pane and try again.", vim.log.levels.ERROR)
  end
end

local function get_visual_text()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return table.concat(lines, "\n")
end

local function is_cell_marker(line)
  return line:match("^%s*#%s*%%%%") or line:match("^%s*#%s*<codecell>")
end

local function current_cell_range()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(0)
  local start_line = 1
  local end_line = total

  for line = cursor, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
    if is_cell_marker(text) then
      start_line = line + 1
      break
    end
  end

  for line = cursor + 1, total do
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
    if is_cell_marker(text) then
      end_line = line - 1
      break
    end
  end

  return start_line, end_line
end

local function send_cell()
  local start_line, end_line = current_cell_range()
  if end_line < start_line then
    notify("Current cell is empty", vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  send_to_slime(table.concat(lines, "\n"))
end

local function send_line()
  send_to_slime(vim.api.nvim_get_current_line())
end

local function send_selection()
  send_to_slime(get_visual_text())
end

local function send_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  send_to_slime(table.concat(lines, "\n"))
end

local function next_cell()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(0)
  for line = cursor + 1, total do
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
    if is_cell_marker(text) then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
  notify("No next cell")
end

local function previous_cell()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  for line = cursor - 1, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
    if is_cell_marker(text) then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
  notify("No previous cell")
end

local function open_python_repl()
  if not in_tmux() then
    notify("This action works best inside tmux", vim.log.levels.WARN)
  end
  vim.fn.system("tmux split-window -h -l 42% 'ipython --no-autoindent'")
  notify("Opened IPython in a tmux pane")
end

vim.keymap.set("n", "<leader>rp", open_python_repl, { desc = "Open IPython REPL in tmux" })
vim.keymap.set("n", "<leader>rl", send_line, { desc = "Send current line to REPL" })
vim.keymap.set("v", "<leader>rs", send_selection, { desc = "Send selection to REPL" })
vim.keymap.set("n", "<leader>rc", send_cell, { desc = "Send current Python cell to REPL" })
vim.keymap.set("n", "<leader>rf", send_file, { desc = "Send whole file to REPL" })
vim.keymap.set("n", "]c", next_cell, { desc = "Next Python cell" })
vim.keymap.set("n", "[c", previous_cell, { desc = "Previous Python cell" })
