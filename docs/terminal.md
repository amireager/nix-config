# 💻 Terminal — Kitty و Tmux

## Kitty

ترمینال emulator سریع با GPU acceleration و پشتیبانی از Wayland.

### میانبرهای کلیدی

| میانبر | عملکرد |
|---|---|
| `Ctrl+Shift+C` | کپی |
| `Ctrl+Shift+V` | پیست |
| `Ctrl+Shift+T` | تب جدید |
| `Ctrl+Shift+W` | بستن تب |
| `Ctrl+Shift+Right` | تب بعدی |
| `Ctrl+Shift+Left` | تب قبلی |
| `Ctrl+Shift+Enter` | پنجره جدید |
| `Ctrl+Shift+L` | بعدی بین پنجره‌ها |

### تنظیمات

- **فونت:** JetBrainsMono Nerd Font، سایز 12
- **شفافیت:** 92%
- **پس‌زمینه:** `#0b0b0e` (تاریک)
- **رنگ‌ها:** Catppuccin Mocha (16 رنگ ANSI)
- **عملکرد:** repaint_delay=10, input_delay=3 (بهینه‌شده برای Wayland)

### اسکرول

```bash
# اسکرول به عقب (در Kitty)
Ctrl+Shift+PageUp     # اسکرول به بالا
Ctrl+Shift+PageDown   # اسکرول به پایین

# یا با ماوس اسکرول کنید
```

---

## Tmux

مالتی‌پلکسر ترمینال. چندین پنجره و پنل در یک ترمینال.

### میانبرهای کلیدی (prefix: `Ctrl+A`)

| میانبر | عملکرد |
|---|---|
| `Ctrl+A` | prefix (شروع تمام دستورات) |
| `Ctrl+A` + `\|` | تقسیم عمودی |
| `Ctrl+A` + `-` | تقسیم افقی |
| `Ctrl+A` + `h/j/k/l` | ناوبری بین پنل‌ها (vim-style) |
| `Ctrl+A` + `c` | پنجره جدید |
| `Ctrl+A` + `n` | پنجره بعدی |
| `Ctrl+A` + `p` | پنجره قبلی |
| `Ctrl+A` + `d` | detach (خروج بدون بستن) |
| `Ctrl+A` + `r` | ریلود کانفیگ |
| `Ctrl+A` + `z` | زوم روی پنل فعلی |
| `Ctrl+A` + `[` | حالت اسکرول (با vim keys) |

### اتصال مجدد

```bash
# لیست sessions
tmux ls

# اتصال مجدد به session
tmux attach -t 0

# session جدید
tmux new -s project-name
```

### تنظیمات

- **prefix:** `Ctrl+A` (راحت‌تر از `Ctrl+B`)
- **شماره‌گذاری:** از 1 شروع می‌شود (نه 0)
- **escape time:** 10ms (سریع برای nvim)
- **حالت کلید:** vi
- **ماوس:** فعال
- **رنگ‌ها:** 256 color + true color passthrough

### کاربرد

- **توسعه:** nvim در یک پنل، terminal در پنل دیگر
- **سرور:** اتصال SSH + detach = بدون از دست دادن کار
- **چند پروژه:** هر پروژه یک session جدا
