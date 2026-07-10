# 📝 Neovim — ویرایشگر کامل

## نصب و تنظیمات پایه

Neovim به عنوان ویرایشگر پیش‌فرض سیستم تنظیم شده:
- `EDITOR=nvim`
- aliasهای `vi`, `vim`, `vimdiff` → `nvim`
- Node.js و Python3 فعال (برای پلاگین‌ها)

## ساختار پیکربندی

```
modules/home/editor/nvim/
├── default.nix              ← نصب پلاگین‌ها و LSPها
└── lua/
    ├── options.lua          ← تنظیمات عمومی
    ├── keymaps.lua          ← میانبرها
    ├── autocmds.lua         ← رویدادهای خودکار
    ├── ui.lua               ← رابط کاربری
    ├── snacks.lua           ← ابزارهای Snacks
    ├── completion.lua       ← تکمیل کد
    ├── lsp.lua              ← تنظیمات LSP
    ├── format-lint.lua      ← فرمت و لینت
    ├── git.lua              ← یکپارچگی git
    ├── productivity.lua     ← ابزارهای بهره‌وری
    ├── run.lua              ← اجرای کد
    └── markdown.lua         ← پیش‌نمایش Markdown
```

## پلاگین‌ها

### رابط کاربری (UI)

| پلاگین | کاربرد |
|---|---|
| **catppuccin-nvim** | طرح رنگ (Mocha) |
| **nvim-web-devicons** | آیکون فایل‌ها |
| **lualine-nvim** | نوار وضعیت پایین |
| **bufferline-nvim** | نوار تب‌ها بالا |
| **which-key-nvim** | نمایش میانبرها هنگام تایپ |
| **snacks-nvim** | مجموعه ابزارهای UI (dashboard, explorer, ...) |

### تحلیل کد (Treesitter)

پلاگین `nvim-treesitter` با ۲۴ زبان نصب شده:

```
bash, c, cpp, css, dockerfile, git_config, git_rebase,
gitattributes, gitcommit, gitignore, html, javascript,
jsdoc, json, lua, luadoc, markdown, markdown_inline,
nix, python, regex, rust, toml, tsx, typescript,
vim, vimdoc, yaml
```

**قابلیت‌ها:**
- رنگ‌بندی syntax هوشمند (بر اساس ساختار AST)
- fold کردن کد
- انتخاب هوشمند بلوک‌ها
- جستجوی ساختاری

### تکمیل کد (Completion)

| پلاگین | کاربرد |
|---|---|
| **blink-cmp** | موتور تکمیل (سریع و مدرن) |
| **friendly-snippets** | مجموعه snippetها |

**نحوه استفاده:**
- تایپ کنید → منوی تکمیل خودکار باز می‌شود
- `Tab` / `Shift+Tab` — حرکت بین گزینه‌ها
- `Enter` — انتخاب
- `Ctrl+Space` — باز کردن دستی
- `Ctrl+E` — بستن

### LSP (پروتکل زبان سرور)

LSPها زبان‌ها را «درک» می‌کنند: تکمیل، خطا، تعریف، رفرنس، تغییر نام.

#### LSPهای نصب‌شده (Global)

| LSP | زبان | قابلیت‌ها |
|---|---|---|
| **pyright** | Python | تکمیل، type checking، go-to-definition |
| **ruff** | Python | لینت و فرمت (بسیار سریع) |
| **nixd** | Nix | تکمیل، تحلیل، hover |
| **lua-language-server** | Lua | تکمیل، تشخیص خطا |
| **bash-language-server** | Bash/Shell | تکمیل، تشخیص خطا |
| **taplo** | TOML | تکمیل، فرمت |
| **yaml-language-server** | YAML | تکمیل، اعتبارسنجی |
| **marksman** | Markdown | تکمیل، پیش‌نمایش |
| **typescript-language-server** | TypeScript/JavaScript | تکمیل، refactor |

#### LSPهای کامنت‌شده (برای devShell)

این LSPها سنگین هستند و بهتر است در devShell استفاده شوند:

| LSP | زبان | دلیل |
|---|---|---|
| `vscode-langservers-extracted` | HTML/CSS/JSON | ~200MB |
| `tailwindcss-language-server` | Tailwind | ~100MB |
| `emmet-language-server` | Emmet | ~50MB |
| `rust-analyzer` | Rust | ~200MB |
| `cargo`, `clippy`, `rustfmt` | Rust toolchain | ~500MB |

#### میانبرهای LSP

| میانبر | عملکرد |
|---|---|
| `gd` | رفتن به تعریف (go to definition) |
| `gD` | رفتن به تعریف در همان فایل |
| `gr` | رفتن به رفرنس‌ها |
| `gi` | رفتن به implementation |
| `K` | نمایش اطلاعات (hover) |
| `<leader>ca` | اقدامات کد (code action) |
| `<leader>cr` | تغییر نام (rename) |
| `<leader>cd` | نمایش خطای تشخیص |
| `[d` / `]d` | خطا قبلی / بعدی |
| `<leader>cf` | فرمت کردن |

### فرمت و لینت

| ابزار | زبان‌ها | نوع |
|---|---|---|
| **conform-nvim** | همه | مدیریت فرمت‌رها |
| **alejandra** | Nix | فرمت‌ر |
| **stylua** | Lua | فرمت‌ر |
| **shfmt** | Shell | فرمت‌ر |
| **prettier** | JS/TS/HTML/CSS/JSON/MD | فرمت‌ر |
| **ruff** | Python | لینت + فرمت |
| **shellcheck** | Bash | لینت |
| **statix** | Nix | لینت (best practices) |
| **deadnix** | Nix | کد استفاده‌نشده |

**فرمت خودکار:** هنگام ذخیره فایل (`:w`)، فرمت‌ر مناسب خودکار اجرا می‌شود.

### Git

| پلاگین | کاربرد |
|---|---|
| **gitsigns-nvim** | نمایش تغییرات در gutter (+, ~, -) |
| **vim-slime** | ارسال کد به ترمینال (REPL) |

**میانبرهای Git (با gitsigns):**

| میانبر | عملکرد |
|---|---|
| `]h` / `[h` | hunk بعدی / قبلی |
| `<leader>hs` | stage hunk |
| `<leader>hr` | reset hunk |
| `<leader>hp` | پیش‌نمایش hunk |
| `<leader>hb` | blame خط فعلی |

### سایر پلاگین‌ها

| پلاگین | کاربرد |
|---|---|
| **mini-nvim** | مجموعه ابزارهای کوچک (pairs, surround, ...) |
| **guess-indent-nvim** | تشخیص خودکار indentation |
| **render-markdown-nvim** | پیش‌نمایش زنده Markdown |
| **plenary-nvim** | کتابخانه ابزار (مورد نیاز بسیاری از پلاگین‌ها) |
| **nvim-ts-autotag** | بستن/تغییر نام خودکار تگ‌های HTML |

## میانبرهای عمومی

### ناوبری

| میانبر | عملکرد |
|---|---|
| `<leader>ff` | جستجوی فایل (find files) |
| `<leader>fg` | جستجوی متن (live grep) |
| `<leader>fb` | لیست بافرها |
| `<leader>fh` | راهنما (help tags) |
| `<leader>fr` | فایل‌های اخیر |
| `<C-h/j/k/l>` | حرکت بین پنجره‌ها |
| `<leader>e` | فایل اکسپلورر |

### ویرایش

| میانبر | عملکرد |
|---|---|
| `<leader>ca` | اقدامات کد |
| `<leader>cf` | فرمت |
| `gcc` | کامنت/آن‌کامنت خط |
| `gc` (visual) | کامنت/آن‌کامنت انتخاب |
| `J` (visual) | اتصال خطوط |
| `<` / `>` (visual) | indent/unindent |
| `<A-j/k>` | حرکت خط به بالا/پایین |

### پنجره‌ها و تب‌ها

| میانبر | عملکرد |
|---|---|
| `<C-w>s` | تقسیم افقی |
| `<C-w>v` | تقسیم عمودی |
| `<C-w>c` | بستن پنجره |
| `<C-w>=` | برابر کردن اندازه |
| `<leader>tt` | تب جدید |
| `<leader>tn/tp` | تب بعدی/قبلی |

### اجرای کد

| میانبر | عملکرد |
|---|---|
| `<leader>rr` | اجرای فایل فعلی |
| `<leader>rt` | اجرای تست |
| `<leader>rp` | ارسال به REPL |

### جستجو و جایگزین

| میانبر | عملکرد |
|---|---|
| `/pattern` | جستجو |
| `n` / `N` | تطابق بعدی / قبلی |
| `:%s/old/new/g` | جایگزینی در کل فایل |
| `:s/old/new/g` | جایگزینی در خط فعلی |

## دستورات مفید

```bash
# باز کردن فایل
nvim file.py           # باز کردن فایل
nvim +42 file.py       # باز کردن در خط 42
nvim .                 # باز کردن دایرکتوری فعلی

# داخل nvim
:Lazy                  # مدیریت پلاگین‌ها
:Mason                 # مدیریت LSP/DAP/Linter
:LspInfo               # اطلاعات LSP فعلی
:checkhealth           # بررسی سلامت nvim
:TSHighlightCapturesUnderCursor  # نمایش highlight group فعلی
```

## عیب‌یابی

```bash
# اگر LSP کار نمی‌کنه:
:LspInfo               # بررسی وضعیت LSP
:checkhealth           # بررسی کلی

# اگر تکمیل کار نمی‌کنه:
:checkhealth completion # بررسی completion

# اگر Treesitter مشکل داره:
:TSInstall <lang>      # نصب دستی زبان
:TSUpdate              # آپدیت همه
```
