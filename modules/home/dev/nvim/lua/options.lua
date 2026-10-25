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
opt.scrolloff = 4
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
opt.winborder = "rounded" -- hover, diagnostics and every float that does not set its own border

-- Folds come from Treesitter (treesitter.lua); start with everything open.
opt.foldlevelstart = 99
opt.foldtext = "" -- keep the first line of a closed fold syntax-highlighted

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
-- EVEN WHEN the keyboard layout is switched to Persian.
-- The mapping below is data, not prose: each Persian character is paired with
-- the Latin key in the same physical position, so do not "translate" it.
--
-- Source: the system layout is XKB `ir` (ISIRI 9147), so every pair below comes
-- from xkeyboard-config's symbols/ir. The letters and digits are exactly what
-- that file defines.
--
-- Rules that are easy to get wrong — a mistake here breaks keys silently:
--   * a part is a list of "<from><to>" pairs; a literal `,` or `;` as <to>
--     must be escaped (`\,`, `\;`);
--   * every pair remaps its <from> key for good, so a pair that looks like an
--     identity, such as `./`, is a real mapping: it turned `.` into `/`, and
--     dot-repeat opened a search prompt. The `.` and `/` keys already produce
--     `.` and `/` on the Persian layout and need no entry;
--   * <from> must never be an ASCII character: 'langmap' applies to every
--     layout, so it would break typing on the US layout too.
local persian_unshifted =
	[[ضq,صw,ثe,قr,فt,غy,عu,هi,خo,حp,ج[,چ],شa,سs,یd,بf,لg,اh,تj,نk,مl,ک\;,گ',ظz,طx,زc,رv,ذb,دn,پm,و\,]]

-- Persian digits ۱-۹ ۰ → ASCII, so counts (`3dd`, `5j`) work without switching layout.
local persian_digits = [[۱1,۲2,۳3,۴4,۵5,۶6,۷7,۸8,۹9,۰0]]

-- Shift layer, so Q W E R T Y U I A S D F G H J K L Z X C V N M and
-- $ % ^ @ # & _ ~ " ? work as well. Written as code points: most are combining
-- marks that merge with the character before them in an editor. Not mappable:
-- O and P, because the layout itself types ASCII there (`]` and `[`), as it
-- does for `( )` and `< >` (swapped relative to the US layout); B, which types
-- an invisible ZWNJ. Use the Latin layout for those.
local persian_shifted = {
	{ 0x0652, "Q" }, -- sukun
	{ 0x064C, "W" }, -- dammatan
	{ 0x064D, "E" }, -- kasratan
	{ 0x064B, "R" }, -- fathatan
	{ 0x064F, "T" }, -- damma
	{ 0x0650, "Y" }, -- kasra
	{ 0x064E, "U" }, -- fatha
	{ 0x0651, "I" }, -- shadda
	{ 0x0624, "A" }, -- waw with hamza above
	{ 0x0626, "S" }, -- yeh with hamza above
	{ 0x064A, "D" }, -- Arabic yeh
	{ 0x0625, "F" }, -- alef with hamza below
	{ 0x0623, "G" }, -- alef with hamza above
	{ 0x0622, "H" }, -- alef with madda above
	{ 0x0629, "J" }, -- teh marbuta
	{ 0x00BB, "K" }, -- right-pointing guillemet
	{ 0x00AB, "L" }, -- left-pointing guillemet
	{ 0x0643, "Z" }, -- Arabic kaf
	{ 0x0653, "X" }, -- maddah above
	{ 0x0698, "C" }, -- jeh
	{ 0x0670, "V" }, -- superscript alef
	{ 0x0654, "N" }, -- hamza above
	{ 0x0621, "M" }, -- hamza
	{ 0x061B, '"' }, -- Arabic semicolon (register prefix)
	{ 0x061F, "?" }, -- Arabic question mark (search backwards)
	{ 0x066C, "@" }, -- thousands separator (macros)
	{ 0x066B, "#" }, -- decimal separator
	{ 0xFDFC, "$" }, -- rial sign (end of line)
	{ 0x066A, "%" }, -- Arabic percent sign (matching pair)
	{ 0x00D7, "^" }, -- multiplication sign (first non-blank)
	{ 0x060C, "&" }, -- Arabic comma
	{ 0x0640, "_" }, -- tatweel
	{ 0x00F7, "~" }, -- division sign (toggle case)
}

local persian_shift_pairs = {}
for _, entry in ipairs(persian_shifted) do
	persian_shift_pairs[#persian_shift_pairs + 1] = vim.fn.nr2char(entry[1]) .. entry[2]
end

opt.langmap = table.concat({ persian_unshifted, persian_digits, table.concat(persian_shift_pairs, ",") }, ",")

-- Disable unused providers to reduce startup overhead.
-- Note: withNodeJs/withPython3 are set in default.nix
-- Only disable providers you're SURE you don't need.
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
