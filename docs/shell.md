# 🐚 Shell — Fish و ابزارهای شل

## Fish Shell

شل تعاملی مدرن. جایگزین bash/zsh با auto-suggestions، syntax highlighting، و completions داخلی.

### تنظیمات

| تنظیم | مقدار |
|---|---|
| greeting | غیرفعال |
| autosuggestion | فعال |
| EDITOR | `nvim` |
| PAGER | `bat --plain` |
| MANPAGER | `bat` (رنگی) |

### alias‌های مهم

| alias | دستور واقعی | کاربرد |
|---|---|---|
| `ls` | `eza --icons` | لیست با آیکون |
| `ll` | `eza -l --icons --git` | لیست با جزئیات |
| `la` | `eza -la --icons --git` | شامل مخفی‌ها |
| `lt` | `eza --tree --level=2` | درخت دایرکتوری |
| `cat` | `bat --style=plain` | نمایش فایل |
| `grep` | `ripgrep` | جستجو |
| `find` | `fd` | پیدا کردن فایل |
| `top` | `btop` | مانیتور سیستم |

### abbreviation‌ها (میانبرهای تایپی)

| مخفف | گسترش | کاربرد |
|---|---|---|
| `n` | `nvim` | باز کردن ویرایشگر |
| `y` | `yazi` | فایل منیجر |
| `sw` | `nh os switch` | بازسازی سیستم |
| `tst` | `nh os test` | تست سیستم |
| `bld` | `nh os build` | بیلد سیستم |
| `gs` | `git status` | وضعیت git |
| `ga` | `git add` | افزودن به git |
| `gc` | `git commit -m` | ثبت تغییرات |
| `gco` | `git checkout` | شاخه/فایل |
| `gp` | `git push` | ارسال |
| `gpl` | `git pull --rebase` | دریافت |

### میانبرهای Fish

| میانبر | عملکرد |
|---|---|
| `Ctrl+R` | جستجوی تاریخچه (atuin) |
| `Ctrl+T` | جستجوی فایل (fzf) |
| `Alt+C` | cd به دایرکتوری (fzf) |
| `Tab` | تکمیل |
| `Ctrl+A` | ابتدای خط |
| `Ctrl+E` | انتهای خط |
| `Ctrl+U` | حذف تا ابتدای خط |
| `Ctrl+K` | حذف تا انتهای خط |
| `Ctrl+W` | حذف کلمه قبلی |

---

## Starship

پرامپت سریع و زیبا.

**نمایش:**
- مسیر فعلی (آبی bold)
- شاخه git (نارنجی bold)
- وضعیت git (قرمز: تغییرات)
- nix shell (برفی ❄️)
- مدت زمان اجرای دستور

---

## Zoxide

جایگزین هوشمند `cd`.

```bash
z project           # cd هوشمند
zi                  # انتخاب تعاملی
zoxide add /path    # افزودن مسیر دستی
```

---

## Direnv + nix-direnv

بارگذاری خودکار محیط توسعه هنگام ورود به دایرکتوری.

```bash
cd my-project       # محیط خودکار بارگذاری می‌شود
direnv deny         # غیرفعال‌سازی موقت
direnv allow        # فعال‌سازی مجدد
direnv status       # نمایش وضعیت
```

---

## FZF

فایندر فازی.

| میانبر | عملکرد |
|---|---|
| `Ctrl+T` | جستجوی فایل |
| `Alt+C` | cd به دایرکتوری |
| `Ctrl+R` | جستجوی تاریخچه (via atuin) |

---

## Carapace

موتور completion برای ۶۰۰+ دستور. خودکار فعال.

---

## Atuin

تاریخچه شل هوشمند (SQLite + fuzzy search).

```bash
Ctrl-R              # جستجوی تاریخچه
atuin stats         # آمار استفاده
atuin sync          # sync بین دستگاه‌ها
```
