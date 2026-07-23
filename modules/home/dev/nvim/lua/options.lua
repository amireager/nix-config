-- Core options focused on speed, clarity, and a modern editing experience.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.showmode = false
opt.cmdheight = 1
opt.laststatus = 3
opt.splitright = true
opt.splitbelow = true
opt.wrap = false
opt.linebreak = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.mouse = "a"
opt.confirm = true

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob '!.git'"
opt.grepformat = "%f:%l:%c:%m"

opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false

opt.updatetime = 200
opt.timeoutlen = 350
opt.ttimeoutlen = 10
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12

opt.clipboard = "unnamedplus"
opt.list = true
opt.listchars = {
	tab = "  ",
	trail = "·",
	extends = "›",
	precedes = "‹",
	nbsp = "␣",
}

-- === Parsi / Persian Keyboard Flow ===
-- 1. Display text correctly
opt.termbidi = true
opt.arabicshape = true

-- 2. Langmap (The Holy Grail for Persian Devs)
-- This allows Vim commands (like h, j, k, l, w, b, d, y) to work flawlessly
-- EVEN WHEN your keyboard layout is set to Persian (فارسی).
opt.langmap =
	[[ضq,صw,ثe,قr,فt,غy,عu,هi,خo,حp,ج[,چ],شa,سs,یd,بf,لg,اh,تj,نk,مl,ک\;,گ',ظz,طx,زc,رv,ذb,دn,پm,و\,./]]

-- Disable unused providers to reduce startup overhead.
-- Note: withNodeJs/withPython3 are set in default.nix
-- Only disable providers you're SURE you don't need.
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
