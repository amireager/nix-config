# 💻 ترمینال — Kitty و Tmux

## Kitty

ترمینال emulator سریع با شتاب‌دهی GPU و پشتیبانی کامل از Wayland.

### تنظیمات

| تنظیم | مقدار |
|---|---|
| فونت | JetBrainsMono Nerd Font — سایز 12 |
| شفافیت | 92% |
| پس‌زمینه | `#0b0b0e` (بسیار تاریک) |
| متن | `#e0e0e0` |
| شکل مCursor | خطی (beam) |
| پدینگ | 4px |
| رنگ‌ها | Catppuccin Mocha (16 رنگ ANSI) |

### میانبرهای کلیدی

| میانبر | عملکرد |
|---|---|
| `Ctrl+Shift+C` | کپی |
| `Ctrl+Shift+V` | پیست |
| `Ctrl+Shift+T` | تب جدید |
| `Ctrl+Shift+W` | بستن تب |
| `Ctrl+Shift+Right` | تب بعدی |
| `Ctrl+Shift+Left` | تب قبلی |
| `Ctrl+Shift+Enter` | پنجره جدید (split) |
| `Ctrl+Shift+L` | حرکت به پنجره بعدی |
| `Ctrl+Shift+PageUp` | اسکرول به بالا |
| `Ctrl+Shift+PageDown` | اسکرول به پایین |
| `Ctrl+Shift+F` | جستجو در خروجی |
| `Ctrl+Shift+Plus` | بزرگ‌نمایی فونت |
| `Ctrl+Shift+Minus` | کوچک‌نمایی فونت |
| `Ctrl+Shift+0` | اندازه پیش‌فرض فونت |

### اسکرول و کپی

```bash
# ورود به حالت اسکرول
Ctrl+Shift+PageUp     # اسکرول به بالا

# با ماوس:
# 1. کلیک و درگ برای انتخاب متن
# 2. خودکار کپی می‌شود (clipboard integration)

# پیست
Ctrl+Shift+V          # پیست از clipboard
```

### عملکرد

| تنظیم | مقدار | توضیح |
|---|---|---|
| repaint_delay | 10ms | تأخیر بازطراحی (کمتر = سریع‌تر) |
| input_delay | 3ms | تأخیر ورودی (بهینه برای Wayland) |
| dynamic_background_opacity | yes | تغییر شفافیت با میانبر |

---

## Tmux

مالتی‌پلکسر ترمینال. چندین پنجره و پنل در یک ترمینال. اتصال SSH بدون از دست دادن کار.

### تنظیمات

| تنظیم | مقدار | توضیح |
|---|---|---|
| prefix | `Ctrl+A` | کلید شروع تمام دستورات (راحت‌تر از `Ctrl+B`) |
| شماره‌گذاری | از 1 | پنجره‌ها از 1 شروع می‌شوند (نه 0) |
| escape time | 10ms | تأخیر Escape (سریع برای nvim) |
| حالت کلید | vi | میانبرهای vim در حالت اسکرول |
| ماوس | فعال | کلیک، درگ، اسکرول |
| رنگ‌ها | 256 + true color | پشتیبانی کامل از رنگ |
| تاریخچه | 50,000 خط | حافظه اسکرول زیاد |

### مفاهیم پایه

```
Session (جلسه)
  └── Window (پنجره) — مثل تب
       └── Pane (پنل) — مثل split
```

- **Session:** یک جلسه کاری مستقل. می‌توان detach کرد و بعداً برگشت.
- **Window:** مثل تب در مرورگر. هر پنجره می‌تواند چندین پنل داشته باشد.
- **Pane:** بخشی از پنجره. می‌توان افقی یا عمودی تقسیم کرد.

### میانبرهای کلیدی

> همه میانبرها بعد از زدن `Ctrl+A` (prefix) فعال می‌شوند.

#### مدیریت پنجره‌ها

| میانبر | عملکرد |
|---|---|
| `Ctrl+A` + `c` | پنجره جدید |
| `Ctrl+A` + `n` | پنجره بعدی |
| `Ctrl+A` + `p` | پنجره قبلی |
| `Ctrl+A` + `0-9` | رفتن به پنجره شماره N |
| `Ctrl+A` + `w` | لیست پنجره‌ها (انتخابی) |
| `Ctrl+A` + `,` | تغییر نام پنجره فعلی |
| `Ctrl+A` + `&` | بستن پنجره فعلی |

#### مدیریت پنل‌ها

| میانبر | عملکرد |
|---|---|
| `Ctrl+A` + `\|` | تقسیم عمودی |
| `Ctrl+A` + `-` | تقسیم افقی |
| `Ctrl+A` + `h` | حرکت به پنل چپ |
| `Ctrl+A` + `j` | حرکت به پنل پایین |
| `Ctrl+A` + `k` | حرکت به پنل بالا |
| `Ctrl+A` + `l` | حرکت به پنل راست |
| `Ctrl+A` + `x` | بستن پنل فعلی |
| `Ctrl+A` + `z` | زوم روی پنل فعلی (fullscreen موقت) |
| `Ctrl+A` + `{` | حرکت پنل به چپ |
| `Ctrl+A` + `}` | حرکت پنل به راست |

#### مدیریت جلسه (Session)

| میانبر | عملکرد |
|---|---|
| `Ctrl+A` + `d` | detach (خروج بدون بستن) |
| `Ctrl+A` + `s` | لیست جلسات |
| `Ctrl+A` + `$` | تغییر نام جلسه فعلی |

#### اسکرول و کپی

| میانبر | عملکرد |
|---|---|
| `Ctrl+A` + `[` | ورود به حالت اسکرول |
| `j` / `k` | حرکت بالا / پایین (در حالت vi) |
| `g` | رفتن به ابتدا |
| `G` | رفتن به انتها |
| `/` | جستجو به پایین |
| `?` | جستجو به بالا |
| `n` | تطابق بعدی |
| `Space` | شروع انتخاب |
| `Enter` | کپی انتخاب |
| `q` | خروج از حالت اسکرول |

#### سایر

| میانبر | عملکرد |
|---|---|
| `Ctrl+A` + `r` | ریلود فایل کانفیگ |
| `Ctrl+A` + `:` | ورود به حالت دستور |
| `Ctrl+A` + `?` | لیست تمام میانبرها |

### دستورات ترمینال

```bash
# لیست جلسات
tmux ls

# جلسه جدید
tmux new -s project-name

# اتصال به جلسه
tmux attach -t project-name

# اتصال به جلسه شماره 0
tmux attach -t 0

# بستن جلسه
tmux kill-session -t project-name

# ارسال دستور به جلسه از بیرون
tmux send-keys -t project-name "command" Enter
```

### الگوهای استفاده

#### توسعه وب

```
┌─────────────────────────────────────┐
│ nvim (کد)          │ terminal       │
│                    │ (server)       │
│                    │                │
├────────────────────┤────────────────│
│ browser preview    │ logs           │
│                    │                │
└─────────────────────────────────────┘
```

```bash
# ساخت جلسه
tmux new -s webdev

# تقسیم عمودی
Ctrl+A + |

# تقسیم پایین سمت چپ
Ctrl+A + -

# حرکت به سمت راست
Ctrl+A + l

# اجرای سرور
npm run dev

# بازگشت به سمت چپ بالا
Ctrl+A + h
Ctrl+A + k

# باز کردن nvim
nvim .
```

#### سرور از راه دور

```bash
# اتصال SSH
ssh user@server

# شروع جلسه tmux
tmux new -s deploy

# کار کنید...
# اگر اتصال قطع شد:

# دوباره اتصال
ssh user@server

# اتصال مجدد به جلسه
tmux attach -t deploy
# → تمام کارها سر جاشون هستن!
```

#### چند پروژه

```bash
# پروژه اول
tmux new -s frontend
# ... کار کنید
Ctrl+A + d  # detach

# پروژه دوم
tmux new -s backend
# ... کار کنید
Ctrl+A + d  # detach

# لیست همه
tmux ls

# سوییچ بین پروژه‌ها
tmux attach -t frontend
# یا
tmux attach -t backend
```

### پیکربندی پیشرفته

فایل کانفیگ Tmux در `modules/home/cli/tmux.nix` تعریف شده. تنظیمات اضافی در `extraConfig`:

```nix
extraConfig = ''
  # True color
  set -ga terminal-overrides ",*256col*:Tc"
  
  # تقسیم با مسیر فعلی
  bind | split-window -h -c "#{pane_current_path}"
  bind - split-window -v -c "#{pane_current_path}"
  
  # ناوبری vim-style
  bind h select-pane -L
  bind j select-pane -D
  bind k select-pane -U
  bind l select-pane -R
  
  # ریلود کانفیگ
  bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
'';
```
