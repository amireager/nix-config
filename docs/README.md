# 📚 مستندات کامل — سیستم NixOS امیر

راهنمای جامع تمام ابزارها، تنظیمات و نحوه استفاده از آن‌ها.

## فهرست مطالب

### سیستم پایه
| فایل | موضوع |
|---|---|
| [system.md](./system.md) | ساختار کلی سیستم، هسته NixOS، سخت‌افزار |
| [nix-workflow.md](./nix-workflow.md) | ابزارهای Nix، دستورات روزانه، مدیریت سیستم |
| [desktop.md](./desktop.md) | Niri compositor، Noctalia، Wayland |
| [network.md](./network.md) | DNS، پروکسی، فایروال، ابزارهای شبکه |

### شل و ترمینال
| فایل | موضوع |
|---|---|
| [shell.md](./shell.md) | Fish، Starship، Zoxide، Direnv، FZF، Atuin، Carapace |
| [terminal.md](./terminal.md) | Kitty، Tmux (کامل با تمام میانبرها) |
| [cli-tools.md](./cli-tools.md) | تمام ابزارهای CLI مدرن (eza, bat, ripgrep, ...) |

### توسعه و ویرایشگر
| فایل | موضوع |
|---|---|
| [editor.md](./editor.md) | Neovim کامل (LSP، Treesitter، میانبرها، پلاگین‌ها) |
| [dev-tools.md](./dev-tools.md) | ابزارهای توسعه (tokei, watchexec, lazygit, ...) |
| [git.md](./git.md) | Git، Delta، GitHub CLI |

### رسانه و مرورگر
| فایل | موضوع |
|---|---|
| [browser.md](./browser.md) | مرورگرها (Zen, Qutebrowser, Brave) |
| [media.md](./media.md) | mpv، imv، zathura |

---

## فلسفه سیستم

> **سبک، سریع، CLI-first**
>
> - حداقل بسته‌های سنگین global
> - ابزارهای مدرن ترمینالی جایگزین ابزارهای قدیمی
> - devShell برای ابزارهای تخصصی (direnv خودکار)
> - دسکتاپ tiling بدون حاشیه (Niri)
> - توسعه با Neovim + Tmux

## اطلاعات سریع

| مقدار | مورد |
|---|---|
| کاربر | `amir` |
| شل | Fish |
| ویرایشگر | Neovim |
| ترمینال | Kitty |
| مالتی‌پلکسر | Tmux (prefix: `Ctrl+A`) |
| دسکتاپ | Niri (Wayland tiling) |
| مرورگر پیش‌فرض | Zen Browser |
| فرمان بازسازی | `nh os switch` |
