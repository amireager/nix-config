-- Global keymaps. Plugin-specific maps are kept near their plugin setup.
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map({ "n", "v" }, "<Space>", "<Nop>", opts)
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Better movement on wrapped lines.
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })

-- Window navigation.
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Window management.
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>ws", "<cmd>split<CR>", { desc = "Horizontal split" })
map("n", "<leader>wq", "<cmd>close<CR>", { desc = "Close window" })
map("n", "<leader>wo", "<cmd>only<CR>", { desc = "Close other windows" })
map("n", "<leader>wh", "<C-w>h", { desc = "Focus left window" })
map("n", "<leader>wj", "<C-w>j", { desc = "Focus lower window" })
map("n", "<leader>wk", "<C-w>k", { desc = "Focus upper window" })
map("n", "<leader>wl", "<C-w>l", { desc = "Focus right window" })
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffers.
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bb", "<cmd>buffer #<CR>", { desc = "Alternate buffer" })
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", function()
  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(0, false)
  else
    vim.cmd.bdelete()
  end
end, { desc = "Delete buffer" })
map("n", "<leader>bD", function()
  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(0, true)
  else
    vim.cmd.bdelete({ bang = true })
  end
end, { desc = "Force delete buffer" })
map("n", "<leader>bo", "<cmd>%bdelete|edit #|bdelete #<CR>", { desc = "Delete other buffers" })

-- Tabs.
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>to", "<cmd>tabonly<CR>", { desc = "Close other tabs" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "]T", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[T", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- Files and quit.
map("n", "<leader>s", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all" })

-- Keep cursor centered during jumps.
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
