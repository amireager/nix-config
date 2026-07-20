-- Mini modules provide small, fast, focused editing tools.
local ok_pairs, pairs = pcall(require, "mini.pairs")
if ok_pairs then pairs.setup() end

local ok_ai, ai = pcall(require, "mini.ai")
if ok_ai then ai.setup({ n_lines = 500 }) end

local ok_surround, surround = pcall(require, "mini.surround")
if ok_surround then
  surround.setup({
    mappings = {
      add = "gsa",
      delete = "gsd",
      find = "gsf",
      find_left = "gsF",
      highlight = "gsh",
      replace = "gsr",
      update_n_lines = "gsn",
    },
  })
end

local ok_comment, comment = pcall(require, "mini.comment")
if ok_comment then comment.setup() end

local ok_move, move = pcall(require, "mini.move")
if ok_move then
  move.setup({
    mappings = {
      left = "<M-h>",
      right = "<M-l>",
      down = "<M-j>",
      up = "<M-k>",
      line_left = "<M-h>",
      line_right = "<M-l>",
      line_down = "<M-j>",
      line_up = "<M-k>",
    },
  })
end

local ok_splitjoin, splitjoin = pcall(require, "mini.splitjoin")
if ok_splitjoin then splitjoin.setup({ mappings = { toggle = "gsj" } }) end

local ok_bracketed, bracketed = pcall(require, "mini.bracketed")
if ok_bracketed then
  bracketed.setup({
    buffer = { suffix = "b" },
    comment = { suffix = "c" },
    diagnostic = { suffix = "d" },
    file = { suffix = "f" },
    indent = { suffix = "i" },
    jump = { suffix = "j" },
    location = { suffix = "l" },
    oldfile = { suffix = "o" },
    quickfix = { suffix = "q" },
    treesitter = { suffix = "t" },
    undo = { suffix = "u" },
    window = { suffix = "w" },
    yank = { suffix = "y" },
  })
end

local ok_jump2d, jump2d = pcall(require, "mini.jump2d")
if ok_jump2d then
  jump2d.setup({
    mappings = { start_jumping = "s" },
    view = { dim = true, n_steps_ahead = 1 },
  })
end

local ok_bufremove, bufremove = pcall(require, "mini.bufremove")
if ok_bufremove then bufremove.setup() end

local ok_trailspace, trailspace = pcall(require, "mini.trailspace")
if ok_trailspace then
  trailspace.setup()

  -- Disable trailing whitespace highlights and list mode on UI/dashboard/special buffers
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType" }, {
    callback = function(args)
      local ft = vim.bo[args.buf].filetype
      local bt = vim.bo[args.buf].buftype
      if bt == "nofile" or bt == "prompt" or bt == "terminal" or ft == "snacks_dashboard" or ft == "lazy" or ft == "trouble" or ft == "help" then
        vim.b[args.buf].minitrailspace_disable = true
        vim.opt_local.list = false
      end
    end,
  })

  vim.keymap.set("n", "<leader>cw", function()
    if not vim.b.minitrailspace_disable then
      trailspace.trim()
      trailspace.trim_last_lines()
    end
  end, { desc = "Trim trailing whitespace" })
end

local ok_guess, guess_indent = pcall(require, "guess-indent")
if ok_guess then guess_indent.setup({ auto_cmd = true }) end

local ok_autotag, autotag = pcall(require, "nvim-ts-autotag")
if ok_autotag then autotag.setup() end
