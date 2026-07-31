# مرجع کلیدها

همه‌ی کلیدها، به تفکیک محیط. جدول‌های Neovim از
`modules/home/dev/nvim/lua/*.lua` و جدول niri از
`modules/home/gui/niri/config.kdl` **تولید** می‌شوند — پس این فایل هیچ‌وقت
با کانفیگ اختلاف پیدا نمی‌کند.

`Mod` کلید Super است · `<leader>` کلید Space است.

> این کارت مرجع است. برای فهمیدن اینکه هر کدام چه کار می‌کنند و چرا:
> [۰۵ دسکتاپ](05-desktop.md) و [۰۶ ادیتور](06-editor.md).

---

# دسکتاپ — niri

## حرکت و جابه‌جایی

| کلید | کار |
| :--- | :--- |
| `Mod+H` `Mod+L` | فوکوس ستون چپ / راست |
| `Mod+J` `Mod+K` | فوکوس پنجره‌ی پایین / بالا در ستون |
| `Mod+←→↑↓` | همان، با جهت‌نما |
| `Mod+Shift+H/L` | جابه‌جایی ستون چپ / راست |
| `Mod+Shift+J/K` | جابه‌جایی پنجره پایین / بالا |
| `Mod+Ctrl+←→↑↓` | همان، با جهت‌نما |
| `Mod+Q` | بستن پنجره |
| `Mod+T` | شناور |
| `Mod+C` | وسط‌چین کردن ستون |

## ستون‌سازی

| کلید | کار |
| :--- | :--- |
| `Mod+W` | کشیدن پنجره‌ی بعدی داخل این ستون |
| `Mod+Period` | بیرون انداختن پنجره از ستون |
| `Mod+Shift+W` | بیرون انداختن (نگاشت دوم) |
| `Mod+G` | نمایش ستون به‌صورت تب |

## اندازه

| کلید | کار |
| :--- | :--- |
| `Mod+R` | چرخش بین عرض‌های از پیش تعیین‌شده |
| `Mod+Minus` `Mod+Equal` | عرض ۱۰٪ کمتر / بیشتر |
| `Mod+F` | بیشینه کردن ستون |
| `Mod+Shift+F` | تمام‌صفحه |
| `Mod+Ctrl+F` | تمام‌صفحه‌ی پنجره‌ای |

## فضاهای کاری

| کلید | کار |
| :--- | :--- |
| `Mod+1`…`Mod+5` | رفتن به فضا |
| `Mod+Shift+1`…`5` | بردن ستون به فضا |
| `Mod+Tab` | نمای کلی |
| `Mod+Shift+Tab` | فضای قبلی |
| `Mod+Wheel` | فضای پایین / بالا |

## اجرا

| کلید | کار |
| :--- | :--- |
| `Mod+Space` | لانچر |
| `Mod+Return` | ترمینال |
| `Mod+Slash` | ترمینال سریع، شناور |
| `Mod+B` | مرورگر |
| `Mod+E` | مدیر فایل |
| `Mod+Shift+E` | مدیر فایل در ترمینال (yazi) |
| `Mod+V` | تاریخچه‌ی کلیپ‌بورد |
| `Mod+N` | منوی وای‌فای |
| `Mod+Alt+C` | ماشین‌حساب |

## تصویر و سیستم

| کلید | کار |
| :--- | :--- |
| `Mod+P` | اسکرین‌شات ناحیه |
| `Mod+Shift+P` | اسکرین‌شات کل صفحه |
| `Mod+Alt+P` | اسکرین‌شات پنجره |
| `Mod+Ctrl+P` | ناحیه مستقیم به کلیپ‌بورد |
| `Mod+Alt+R` | ضبط صفحه |
| `Mod+Alt+K` | نمایش کلیدها روی صفحه |
| `Mod+S` | مرکز کنترل |
| `Mod+Comma` | تنظیمات |
| `Mod+I` | جلوگیری از خواب |
| `Mod+X` | قفل |
| `Mod+Shift+X` | قفل با swaylock |
| `Mod+Escape` | سپردن کلیدها به پنجره |
| `Mod+Shift+Q` | خروج از نشست |

## کلیدهای سخت‌افزاری

موقع قفل بودن صفحه هم کار می‌کنند.

| کلید | کار |
| :--- | :--- |
| `XF86AudioRaiseVolume` / `Lower` | صدا |
| `XF86AudioMute` | بی‌صدا |
| `XF86MonBrightnessUp` / `Down` | روشنایی |
| `Mod+TouchpadScrollUp` / `Down` | صدا از تاچ‌پد |

---

# ادیتور — Neovim

`<leader>` کلید Space است. بزنش و صبر کن تا `which-key` فهرست کند.
`n` عادی · `v` بصری · `i` درج · `x` بلوکی · `o` عملگر · `c` خط فرمان

### `<leader>Q` — 

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>Q` | `n` | Quit all |

### `<leader>a` — 🤖 هوش مصنوعی

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>a?` | `n` | AI status |
| `<leader>aC` | `n` | AI commit message |
| `<leader>aa` | `nv` | AI chat (toggle) |
| `<leader>ad` | `v` | AI explain diagnostics |
| `<leader>ae` | `v` | AI explain selection |
| `<leader>af` | `v` | AI fix selection |
| `<leader>ag` | `n` | AI agent mode (can edit files!) |
| `<leader>ah` | `n` | AI chat history |
| `<leader>ai` | `n` | AI inline edit |
| `<leader>am` | `n` | AI model (default for new chats) |
| `<leader>ap` | `nv` | AI actions (palette) |
| `<leader>as` | `v` | Send selection to chat |
| `<leader>at` | `v` | AI write unit tests |
| `<leader>ax` | `n` | AI write a : command |

### `<leader>b` — 📑 بافرها

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>bD` | `n` | Force delete buffer |
| `<leader>bb` | `n` | Alternate buffer |
| `<leader>bd` | `n` | Delete buffer |
| `<leader>bn` | `n` | Next buffer |
| `<leader>bo` | `n` | Delete other buffers |
| `<leader>bp` | `n` | Previous buffer |

### `<leader>c` — ⚡ کد و تغییرنام

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>cF` | `n` | Toggle autoformat |
| `<leader>cR` | `n` | Rename file (Snacks) |
| `<leader>cf` | `nv` | Format file or selection |
| `<leader>cw` | `n` | Trim trailing whitespace |

### `<leader>d` — 🐞 دیباگ

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>dB` | `n` | Breakpoint: conditional |
| `<leader>dC` | `n` | Run to cursor |
| `<leader>dO` | `n` | Step out |
| `<leader>dR` | `n` | REPL toggle |
| `<leader>dT` | `n` | Python: debug test class |
| `<leader>dX` | `n` | Breakpoints: clear all |
| `<leader>db` | `n` | Breakpoint: toggle |
| `<leader>dc` | `n` | Continue / start |
| `<leader>de` | `nv` | Evaluate expression |
| `<leader>di` | `n` | Step into |
| `<leader>dj` | `n` | Stack: down a frame |
| `<leader>dk` | `n` | Stack: up a frame |
| `<leader>dl` | `n` | Breakpoint: log point (no stop) |
| `<leader>do` | `n` | Step over |
| `<leader>dq` | `n` | Terminate session |
| `<leader>dr` | `n` | Restart session |
| `<leader>ds` | `v` | Python: debug selection |
| `<leader>dt` | `n` | Python: debug test under cursor |
| `<leader>du` | `n` | UI toggle |

### `<leader>e` — 📁 اکسپلورر

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>ee` | `n` | Open Snacks explorer (Snacks) |
| `<leader>ef` | `n` | Explorer at current file (Snacks) |
| `<leader>ey` | `n` | Open yazi in tmux (Yazi) |

### `<leader>f` — 🔍 جستجو

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>fC` | `n` | Colorschemes (Snacks) |
| `<leader>fD` | `n` | Workspace diagnostics (Snacks) |
| `<leader>fH` | `n` | Highlights (Snacks) |
| `<leader>fI` | `n` | Find icons & emojis (Snacks) |
| `<leader>fR` | `n` | Registers (Snacks) |
| `<leader>fS` | `n` | Workspace symbols (Snacks) |
| `<leader>fa` | `n` | Find autocmds (Snacks) |
| `<leader>fb` | `n` | Find buffers (Snacks) |
| `<leader>fc` | `n` | Find commands (Snacks) |
| `<leader>fd` | `n` | Buffer diagnostics (Snacks) |
| `<leader>ff` | `n` | Find files (Snacks) |
| `<leader>fg` | `n` | Find git files (Snacks) |
| `<leader>fh` | `n` | Find help (Snacks) |
| `<leader>fj` | `n` | Jump list (Snacks) |
| `<leader>fk` | `n` | Find keymaps (Snacks) |
| `<leader>fl` | `n` | Find current buffer lines (Snacks) |
| `<leader>fm` | `n` | Find man pages (Snacks) |
| `<leader>fp` | `n` | Find projects (Snacks) |
| `<leader>fq` | `n` | Quickfix list (Snacks) |
| `<leader>fr` | `n` | Resume last picker (Snacks) |
| `<leader>fs` | `n` | Document symbols (Snacks) |
| `<leader>ft` | `n` | Find TODO/FIXME comments (Snacks) |
| `<leader>fu` | `n` | Undo history (Snacks) |
| `<leader>fw` | `n` | Find word under cursor (Snacks) |

### `<leader>g` —  گیت

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>gB` | `n` | Git branches |
| `<leader>gF` | `n` | Git log current file (Snacks) |
| `<leader>gH` | `n` | File history (Diffview) |
| `<leader>gL` | `n` | Git log (Snacks) |
| `<leader>gV` | `n` | Diff view close (Diffview) |
| `<leader>gc` | `n` | 🚀 Commit UI (Neogit) |
| `<leader>gg` | `n` | Lazygit (Snacks) |
| `<leader>gh` | `n` | Project history (Diffview) |
| `<leader>gl` | `n` | Git log |
| `<leader>go` | `n` | Open in browser (Snacks) |
| `<leader>gv` | `n` | Diff view open (Diffview) |

### `<leader>m` — 📝 مارک‌داون

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>md` | `n` | Disable markdown render |
| `<leader>me` | `n` | Enable markdown render |
| `<leader>mt` | `n` | Toggle markdown render |

### `<leader>n` — 

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>n` | `n` | Notification history (Snacks) |

### `<leader>q` — 

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>q` | `n` | Quit window |

### `<leader>r` — ▶️ اجرا و REPL

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>rc` | `n` | Send current Python cell to REPL |
| `<leader>rf` | `n` | Send whole file to REPL |
| `<leader>rl` | `n` | Send current line to REPL |
| `<leader>rp` | `n` | Open IPython REPL in tmux |
| `<leader>rs` | `v` | Send selection to REPL |

### `<leader>s` — 

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>s` | `n` | Save file |

### `<leader>t` — 💻 تب و ترمینال

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>tc` | `n` | Close tab |
| `<leader>tf` | `n` | Terminal bottom float (Snacks) |
| `<leader>th` | `n` | Previous tab |
| `<leader>tl` | `n` | Next tab |
| `<leader>tn` | `n` | New tab |
| `<leader>to` | `n` | Close other tabs |
| `<leader>tt` | `n` | Terminal toggle (Snacks) |

### `<leader>u` — 🎨 ظاهر

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>uS` | `n` | Toggle spell check |
| `<leader>uW` | `n` | Toggle word wrap |
| `<leader>uc` | `n` | Toggle conceal (Snacks) |
| `<leader>ud` | `n` | Toggle diagnostics (Snacks) |
| `<leader>ui` | `n` | Toggle indent guides (Snacks) |
| `<leader>ul` | `n` | Toggle relative line numbers |
| `<leader>un` | `n` | Dismiss notifications (Snacks) |
| `<leader>us` | `n` | Toggle smooth scroll (Snacks) |
| `<leader>uw` | `n` | Toggle word highlight (Snacks) |
| `<leader>ux` | `n` | Toggle treesitter context |
| `<leader>uz` | `n` | Zen mode toggle (Snacks) |

### `<leader>w` — 🪟 پنجره‌ها

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>wh` | `n` | Focus left window |
| `<leader>wj` | `n` | Focus lower window |
| `<leader>wk` | `n` | Focus upper window |
| `<leader>wl` | `n` | Focus right window |
| `<leader>wo` | `n` | Close other windows |
| `<leader>wq` | `n` | Close window |
| `<leader>ws` | `n` | Horizontal split |
| `<leader>wv` | `n` | Vertical split |

### `<leader>x` — 🚨 تشخیص‌ها

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<leader>xL` | `n` | Location list (Trouble) |
| `<leader>xQ` | `n` | Quickfix list (Trouble) |
| `<leader>xX` | `n` | Buffer diagnostics (Trouble) |
| `<leader>xl` | `n` | LSP references (Trouble) |
| `<leader>xs` | `n` | Symbols (Trouble) |
| `<leader>xt` | `n` | TODO list (Trouble) |
| `<leader>xx` | `n` | Diagnostics (Trouble) |

### بیرون از leader

| کلید | حالت | کار |
| :--- | :--- | :--- |
| `<C-Down>` | `n` | Decrease window height |
| `<C-Left>` | `n` | Decrease window width |
| `<C-Right>` | `n` | Increase window width |
| `<C-Up>` | `n` | Increase window height |
| `<C-d>` | `n` | Half page down |
| `<C-h>` | `n` | Go to left window |
| `<C-j>` | `n` | Go to lower window |
| `<C-k>` | `n` | Go to upper window |
| `<C-l>` | `n` | Go to right window |
| `<C-s>` | `c` | Toggle flash in search |
| `<C-u>` | `n` | Half page up |
| `<Esc>` | `n` | Clear search highlight |
| `<S-Tab>` | `n` | Previous buffer |
| `<Space>` | `nv` | Exit insert mode |
| `<Tab>` | `n` | Next buffer |
| `<leader>,` | `n` | Buffers (Snacks) |
| `<leader>/` | `n` | Grep (Snacks) |
| `<leader>:` | `n` | Command history (Snacks) |
| `<leader><space>` | `n` | Smart find (Snacks) |
| `H` | `nx` | Top of screen |
| `L` | `nx` | Bottom of screen |
| `N` | `n` | Previous search result |
| `R` | `ox` | Treesitter search |
| `S` | `nox` | Flash treesitter select |
| `[T` | `n` | Previous tab |
| `[c` | `n` | Previous Python cell |
| `[x` | `n` | Jump to context (function header) |
| `]T` | `n` | Next tab |
| `]c` | `n` | Next Python cell |
| `]h` | `n` | 📝 Neogit UI (Neogit) |
| `gI` | `n` | LSP implementations (Snacks) |
| `gd` | `n` | LSP definitions (Snacks) |
| `gr` | `n` | LSP references (Snacks) |
| `gy` | `n` | LSP type definitions (Snacks) |
| `j` | `n` | Down |
| `k` | `n` | Up |
| `n` | `n` | Next search result |
| `q` | `n` | Close window |
| `r` | `o` | Remote flash |
| `s` | `nox` | Flash jump |

---

# بافر چت هوش مصنوعی

فقط داخل بافر چت CodeCompanion کار می‌کنند.

| کلید | کار |
| :--- | :--- |
| `?` | همه‌ی کلیدهای این بافر |
| `<CR>` | ارسال |
| `ga` | عوض کردن adapter و مدل |
| `gr` | تولید دوباره‌ی آخرین جواب |
| `gx` | پاک کردن گفتگو |
| `gy` | کپی آخرین بلاک کد |
| `gs` | خاموش/روشن system prompt |
| `gd` | دیباگ — دقیقاً چه چیزی فرستاده شد |
| `gh` | تاریخچه‌ی چت‌ها |
| `gty` | حالت yolo — تأیید خودکار ابزارها |
| `q` | قطع درخواست در حال اجرا |

سه کاراکتر شروع‌کننده: `#{buffer}` برای ضمیمه کردن، `/file` برای دستور،
`@{agent}` برای دادن ابزار به مدل.

---

# تولید دوباره‌ی این فایل

```sh
# niri
grep -oP '^\s*\K(Mod|XF86|Print)\S*.*\{.*\}' modules/home/gui/niri/config.kdl

# neovim
rg -o 'keymap\.set\(.*?desc\s*=\s*"[^"]*"' modules/home/dev/nvim/lua/
```

داخل خود ادیتور، `<leader>fk` همه‌ی کلیدها را جستجوپذیر نشان می‌دهد و
`:map` وضعیت زنده را — که اگر این فایل و کانفیگ اختلاف داشتند، جواب واقعی
همان است.
