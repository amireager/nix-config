# 📝 Editor — Neovim + LazyVim

## Neovim

ادیتور متن قابل‌توسعه با پشتیبانی از LSP، Treesitter، و plugin ecosystem.

### میانبرهای پایه

| میانبر | عملکرد |
|---|---|
| `i` | ورود به حالت insert |
| `Esc` | خروج از حالت insert |
| `:w` | ذخیره |
| `:q` | خروج |
| `:wq` | ذخیره و خروج |
| `:q!` | خروج بدون ذخیره |
| `u` | undo |
| `Ctrl+r` | redo |
| `/pattern` | جستجو |
| `n` | تطابق بعدی |
| `N` | تطابق قبلی |
| `:%s/old/new/g` | جایگذاری همه |

### میانبرهای LazyVim

| میانبر | عملکرد |
|---|---|
| `Space` | leader key |
| `Space + ff` | جستجوی فایل (Telescope) |
| `Space + fg` | جستجوی متن (grep) |
| `Space + fb` | لیست بافرها |
| `Space + fr` | فایل‌های اخیر |
| `Space + e` | فایل explorer |
| `Space + gg` | lazygit |
| `Space + cf` | فرمت فایل |
| `Space + ca` | code action |
| `Space + cd` | نمایش diagnostics |
| `Space + cr` | تغییر نام |
| `gd` | go to definition |
| `gr` | references |
| `K` | hover documentation |
| `Ctrl+d` | اسکرول نیم صفحه |
| `Ctrl+u` | اسکرول نیم صفحه به بالا |
| `gcc` | comment/uncomment خط |
| `gc` | comment/uncomment انتخاب |

### LSP‌های فعال

| LSP | زبان | قابلیت‌ها |
|---|---|---|
| **pyright** | Python | type checking, completion, go-to-def |
| **ruff** | Python | linting, formatting |
| **rust-analyzer** | Rust | completion, diagnostics, inlay hints |
| **typescript-language-server** | TS/JS | completion, refactoring |
| **nixd** | Nix | completion, diagnostics |
| **lua-language-server** | Lua | completion, diagnostics |
| **bash-language-server** | Bash | completion, diagnostics |
| **marksman** | Markdown | completion, diagnostics |
| **taplo** | TOML | completion, diagnostics |
| **yaml-language-server** | YAML | completion, diagnostics |

### Treesitter Grammars

زبان‌های نصب‌شده برای syntax highlighting و code understanding:

bash, c, cpp, css, dockerfile, git_config, git_rebase, html, javascript, json, lua, markdown, nix, python, regex, rust, toml, tsx, typescript, vim, yaml

### Plugins فعال

| Plugin | وظیفه |
|---|---|
| **catppuccin-nvim** | تم رنگی |
| **lualine-nvim** | statusline |
| **bufferline-nvim** | تب‌ها |
| **which-key-nvim** | نمایش میانبرها |
| **snacks-nvim** | ابزارهای متنوع |
| **nvim-treesitter** | syntax highlighting |
| **blink-cmp** | completion |
| **nvim-lspconfig** | LSP integration |
| **conform.nvim** | فرمت‌بندی |
| **gitsigns.nvim** | git signs در gutter |
| **mini.nvim** | ابزارهای کوچک متنوع |
| **render-markdown.nvim** | نمایش Markdown |
| **guess-indent.nvim** | تشخیص خودکار indentation |

### فرمت‌بندی (conform.nvim)

فرمت‌بندی خودکار هنگام ذخیره:

| زبان | فرمتتر |
|---|---|
| Python | ruff |
| Rust | rustfmt |
| Nix | alejandra |
| Lua | stylua |
| JS/TS | prettier |
| Bash | shfmt |
| TOML | taplo |
| YAML | yamlfmt |

### دیباگ (اختیاری)

اگر `nvim-dap` نصب باشد:

| میانبر | عملکرد |
|---|---|
| `Space + db` | breakpoint |
| `Space + dc` | continue |
| `Space + ds` | step over |
| `Space + di` | step into |
| `Space + do` | step out |
| `Space + du` | UI toggle |
