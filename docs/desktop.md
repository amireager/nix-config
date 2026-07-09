# 🖥️ Desktop — Niri، Noctalia، و Wayland Tools

## Niri

کامپوزیتور Wayland اسکرول‌پذیر. تایلینگ بدون overlapping windows.

### میانبرهای کلیدی (Mod = Super)

#### ناوبری

| میانبر | عملکرد |
|---|---|
| `Mod + h/j/k/l` | فوکوس به چپ/پایین/بالا/راست |
| `Mod + Arrow Keys` | فوکوس (alternatve) |
| `Mod + Tab` | overview (همه ویندوها) |
| `Mod + Shift + Tab` | workspace قبلی |
| `Mod + 1-5` | رفتن به workspace |
| `Mod + WheelScroll` | اسکرول بین workspace‌ها |

#### مدیریت ویندو

| میانبر | عملکرد |
|---|---|
| `Mod + Q` | بستن ویندو |
| `Mod + Shift + Q` | خروج از niri |
| `Mod + F` | maximize ستون |
| `Mod + Shift + F` | fullscreen |
| `Mod + Ctrl + F` | windowed fullscreen |
| `Mod + T` | toggle floating |
| `Mod + C` | center ستون |
| `Mod + R` | تغییر اندازه preset |

#### حرکت دادن

| میانبر | عملکرد |
|---|---|
| `Mod + Shift + h/j/k/l` | حرکت ویندو |
| `Mod + Ctrl + Arrow` | حرکت ویندو (alternative) |
| `Mod + Shift + 1-5` | انتقال به workspace |
| `Mod + Period` | خارج کردن ویندو از ستون |

#### تغییر اندازه

| میانبر | عملکرد |
|---|---|
| `Mod + Minus` | کاهش عرض 10% |
| `Mod + Equal` | افزایش عرض 10% |

#### اپلیکیشن‌ها

| میانبر | عملکرد |
|---|---|
| `Mod + Return` | باز کردن Kitty |
| `Mod + Slash` | ترمینال سریع (floating) |
| `Mod + B` | مرورگر Zen |
| `Mod + E` | Thunar |
| `Mod + Shift + E` | yazi در Kitty |

#### Noctalia

| میانبر | عملکرد |
|---|---|
| `Mod + Space` | لانچر |
| `Mod + S` | control center |
| `Mod + Comma` | تنظیمات |
| `Mod + I` | caffeine toggle |

#### رسانه

| میانبر | عملکرد |
|---|---|
| `Volume Up/Down` | کنترل صدا |
| `Brightness Up/Down` | کنترل روشنایی |
| `Mod + P` | اسکرین‌شات |
| `Mod + Shift + P` | اسکرین‌شات صفحه |
| `Mod + Alt + P` | اسکرین‌شات ویندو |

---

## Noctalia

دسکتاپ شل کامل برای Wayland: نوار، لانچر، نوتیفیکیشن، wallpaper، dock، OSD، lock screen.

### اجزا

| جزء | توضیح |
|---|---|
| **Bar** | نوار بالا — ساعت، وضعیت سیستم، workspace‌ها |
| **Launcher** | اپ‌لانچر (Mod + Space) |
| **Notifications** | سیستم نوتیفیکیشن |
| **Control Center** | تنظیمات سریع (WiFi، Bluetooth، صدا) |
| **Dock** | نوار پایین — اپ‌های پین‌شده |
| **Wallpaper** | مدیریت تصویر پس‌زمینه |
| **Lock Screen** | قفل صفحه |
| **OSD** | نمایش صدا/روشنایی |

### تم

- **حالت:** تاریک
- **تم:** Catppuccin
- **فونت:** JetBrainsMono Nerd Font

---

## Wayland Tools

### grim + slurp

اسکرین‌شات در Wayland.

```bash
# اسکرین‌شات کل صفحه
grim screenshot.png

# اسکرین‌شات ناحیه انتخاب‌شده
grim -g "$(slurp)" screenshot.png

# اسکرین‌شات و ارسال به کلیپبورد
grim -g "$(slurp)" - | wl-copy
```

### wl-screenrec

ضبط صفحه در Wayland.

```bash
# ضبط کل صفحه
wl-screenrec -f recording.mp4

# ضبط ناحیه خاص
wl-screenrec -g "$(slurp)" -f recording.mp4

# توقف: Ctrl+C
```

### brightnessctl

کنترل روشنایی صفحه.

```bash
brightnessctl                  # نمایش روشنایی فعلی
brightnessctl set 50%          # تنظیم روشنایی
brightnessctl set +10%         # افزایش
brightnessctl set 10%-         # کاهش
```

### pamixer

کنترل صدا از ترمینال.

```bash
pamixer --get-volume           # نمایش ولوم فعلی
pamixer --set-volume 50        # تنظیم ولوم
pamixer --increase 5           # افزایش
pamixer --decrease 5           # کاهش
pamixer --toggle-mute          # mute/unmute
pamixer --get-mute             # وضعیت mute
```

### bluetui

مدیریت بلوتوث با رابط TUI.

```bash
bluetui                        # باز کردن bluetui
```

### wl-clipboard

کپی/پیست در Wayland.

```bash
echo "text" | wl-copy          # کپی متن
wl-paste                       # پیست
wl-paste > file.txt            # پیست در فایل
cat image.png | wl-copy -t image/png  # کپی تصویر
```

### xwayland-satellite

اجرای اپ‌های X11 در Wayland.

```bash
# خودکار فعال — اپ‌های X11 بدون تنظیمات اضافی اجرا می‌شوند
# DISPLAY=:0 تنظیم شده
```

### networkmanagerapplet

آیکون شبکه در سیستم tray.

```bash
# خودکار اجرا می‌شود — نیازی به دستور نیست
```
