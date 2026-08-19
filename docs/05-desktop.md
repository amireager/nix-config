# ۰۵ — Desktop: Niri، Noctalia و workflow گرافیکی

Desktop از چند لایه تشکیل شده است. فهمیدن مالک هر لایه مهم‌تر از حفظ‌کردن نام packageهاست.

```text
NixOS
├── SDDM session
├── Niri package/module
├── PipeWire
├── Bluetooth
├── portals
└── Thunar services

Home Manager
├── Niri config.kdl
├── Noctalia user service
├── terminal/browser/media
├── Fuzzel helpers
├── clipboard history
└── XDG defaults/theme
```

---

# چرا Niri؟

Window managerهای tiling معمولاً صفحه‌ی ثابت را میان پنجره‌های بیشتر تقسیم می‌کنند. Niri workspace را به نوار افقی ستون‌ها تبدیل می‌کند:

```text
[ Editor ] [ Terminal ] [ Browser ] [ Documentation ] [ ... ]
                  └──── viewport ────┘
```

افزودن پنجره اندازه‌ی همه‌ی پنجره‌های قبلی را اجباراً کوچک نمی‌کند؛ viewport به ستون بعدی حرکت می‌کند.

واحد اصلی **column** است:

- یک column می‌تواند یک window تمام‌قد داشته باشد؛
- چند window می‌توانند داخل یک column روی هم قرار بگیرند؛
- width column مستقل از تعداد columnهاست؛
- workspaceها همچنان جداسازی سطح بالاتر را می‌دهند.

---

# startup و service ownership

## NixOS

- SDDM login session را شروع می‌کند؛
- Niri compositor و Wayland session را فراهم می‌کند؛
- portalها screen sharing و file chooser را به applicationها می‌دهند؛
- PipeWire audio/video graph را مدیریت می‌کند؛
- Bluetooth در boot روشن نمی‌شود؛
- Thunar/GVFS/Tumbler file management و thumbnail را فراهم می‌کنند.

## Home Manager

- `config.kdl` رفتار Niri را تعیین می‌کند؛
- Noctalia با user systemd service اجرا می‌شود؛
- Cliphist، Udiskie و user applicationها فعال می‌شوند؛
- GTK/icon/cursor/XDG associationها user-specific هستند.

Niri config هیچ startup command موازی برای Noctalia ندارد؛ systemd user service مالک lifecycle آن است.

---

# Noctalia چه چیزی را فراهم می‌کند؟

| قابلیت | مسیر استفاده |
| :--- | :--- |
| Launcher | `Mod+Space` |
| Control centre | `Mod+S` |
| Settings | `Mod+Comma` |
| Lock | `Mod+X` |
| Volume/Brightness OSD | media key و touchpad binding |
| Caffeine | `Mod+I` |
| Bar/Dock | declarative base + GUI state |
| Notification daemon | Noctalia |
| Wallpaper | Noctalia |
| Polkit prompt | Noctalia graphical agent |

Base theme، bar، dock، notification و Polkit در Nix ثبت شده‌اند. زمان‌بندی idle/lock/display/suspend عمداً در Noctalia Settings باقی می‌ماند.

## چرا idle کاملاً declarative نیست؟

Caffeine باید بتواند timerها را موقتاً متوقف و دوباره فعال کند. اگر Nix زمان‌ها را force کند، GUI ممکن است ظاهراً تغییر کند ولی source declarative دوباره آن را override کند.

پس قرارداد:

- **Nix:** قابلیت و defaultهای ظاهری؛
- **Noctalia writable state:** زمان‌بندی runtime؛
- **Caffeine:** توقف موقت.

---

# launch و applicationها

| کار | کلید | ابزار |
| :--- | :--- | :--- |
| Terminal اصلی | `Mod+Return` | Kitty |
| Quick terminal | `Mod+Slash` | Kitty با class جدا |
| Browser | `Mod+B` | Zen Browser |
| File manager | `Mod+E` | Thunar |
| Yazi | `Mod+Shift+E` | Kitty + Yazi |
| Clipboard history | `Mod+V` | Cliphist + Fuzzel |
| Wi-Fi selector | `Mod+N` | networkmanager_dmenu + Fuzzel |
| Calculator | `Mod+Alt+C` | Fuzzel + qalc + clipboard |

WezTerm نیز نصب و پیکربندی شده و برای terminal دوم یا آزمایش rendering در دسترس است، ولی keybinding اصلی Kitty است.

---

# workflow ستون‌ها

## ساخت workspace کاری

1. `Mod+Return` برای terminal؛
2. `Mod+B` برای browser؛
3. با `Mod+Left/Right` بین columnها حرکت؛
4. width را با bindingهای preset تغییر؛
5. window مرتبط را داخل column فعلی consume/expel کنید؛
6. برای context جدا به workspace بعدی بروید.

## پیدا کردن window گمشده

- Overview را باز کنید؛
- workspace و column را بصری پیدا کنید؛
- hotkey overlay با `Mod+Shift+Slash` shortcutهای compositor را نشان می‌دهد.

Fullscreen و maximize را یکی ندانید: fullscreen chrome و panel را می‌پوشاند؛ maximize فقط geometry window/column را تغییر می‌دهد.

---

# Clipboard

Cliphist clipboard text/image history را نگه می‌دارد:

```text
Mod+V
  → cliphist list
  → Fuzzel selection
  → cliphist decode
  → wl-copy
```

برای secretها فرض نکنید clipboard history secure vault است. Password manager باید auto-clear policy خودش را داشته باشد و secret حساس بعد از استفاده پاک شود.

Commandهای دستی diagnosis:

```bash
cliphist list | head
cliphist wipe
wl-paste --list-types
```

`cliphist wipe` destructive است و کل history را پاک می‌کند.

---

# Screenshot، recording و key display

| کار | کلید | رفتار |
| :--- | :--- | :--- |
| Region screenshot → clipboard | `Mod+Ctrl+P` | Slurp → Grim → wl-copy |
| Record toggle/GUI | `Mod+Alt+R` | GPU Screen Recorder GTK |
| Keycaster | `Mod+Alt+K` | wshowkeys |

## screenshot pipeline

```bash
slurp | grim -g - - | wl-copy
```

- Slurp geometry را برمی‌گرداند؛
- Grim همان region را به stdout می‌فرستد؛
- wl-copy image را وارد clipboard می‌کند.

اگر selection cancel شود نباید screenshot قدیمی به‌عنوان نتیجه‌ی جدید فرض شود؛ notification helper را با نتیجه‌ی واقعی command مقایسه کنید.

## recording

Helper اگر process recorder فعال باشد SIGINT می‌فرستد تا recording درست finalize شود؛ در غیر این صورت GUI را باز می‌کند. Kill سخت می‌تواند container ویدیو را ناقص کند.

---

# Audio، brightness و Bluetooth

Media keyها به Noctalia IPC می‌روند تا state و OSD هماهنگ باشند. `pamixer` و `brightnessctl` برای diagnosis/manual use نیز global هستند.

```bash
pamixer --get-volume-human
brightnessctl info
bluetoothctl show
bluetui
```

Bluetooth در boot خاموش است تا power و discoverability بی‌دلیل فعال نباشد. Blueman/Noctalia/TUI هرکدام interface متفاوت‌اند؛ Bluetooth daemon در NixOS مالک device state است.

---

# File و removable media

- Thunar file manager گرافیکی؛
- GVFS برای integration و remote locations؛
- Tumbler/ffmpegthumbnailer برای preview؛
- Udiskie برای automount و notification removable drive؛
- Yazi برای workflow terminal.

بررسی mount:

```bash
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS,LABEL
findmnt --real
```

USBGuard و automount دو لایه‌ی جدا هستند: ابتدا device policy اجازه می‌دهد، سپس storage mount می‌شود.

---

# XDG و default application

Associationها در `modules/home/gui/xdg.nix` نگه‌داری می‌شوند. برای دیدن default مؤثر:

```bash
xdg-mime query default text/plain
xdg-mime query default application/pdf
xdg-mime query default x-scheme-handler/https
```

بازکردن تستی:

```bash
xdg-open document.pdf
xdg-open https://example.com
```

اگر برنامه‌ی اشتباه باز شد، ابتدا association را بررسی کنید؛ افزودن alias یا wrapper جدید آخرین راه است.

---

# Wayland و XWayland

Applicationهای native Wayland از session variables و portal استفاده می‌کنند. `xwayland-satellite` برای برنامه‌های X11 legacy نصب است و Niri آن را در صورت نیاز راه‌اندازی می‌کند.

`DISPLAY` دستی set نمی‌شود؛ compositor/XWayland آن را در زمان درست می‌سازد. Set کردن global آن می‌تواند application native را به backend اشتباه ببرد.

Diagnosis:

```bash
printf 'session=%s desktop=%s display=%s wayland=%s\n' \
  "$XDG_SESSION_TYPE" "$XDG_CURRENT_DESKTOP" "$DISPLAY" "$WAYLAND_DISPLAY"

niri msg version
niri msg outputs
```

---

# Portal و screen sharing

Browser، recorder و conferencing app برای screen capture Wayland به XDG Desktop Portal نیاز دارند.

بررسی user serviceها:

```bash
systemctl --user status xdg-desktop-portal.service
systemctl --user status xdg-desktop-portal-gtk.service
```

این commandها برای diagnosis هستند. Restart کورکورانه‌ی portal وسط session می‌تواند capture فعال را قطع کند.

---

# تایپ فارسی و CapsLock

## layout سیستم

XKB دو layout دارد:

```text
us,ir
```

Toggle با Alt+Shift است.

## Keyd

CapsLock در سطح evdev:

- tap کوتاه → Escape؛
- hold → Super/Meta.

این رفتار قبل از Niri و application اعمال می‌شود، بنابراین terminal و editor نیز همان key event را می‌بینند.

## Neovim `langmap`

وقتی layout فارسی است، keyهای command-mode به معادل حرکتی لاتین map می‌شوند تا برای حرکت کوتاه مجبور به تعویض layout نباشید. Insert mode همچنان متن فارسی عادی می‌نویسد.

---

# Lock و session safety

```text
Mod+X       Noctalia lock
Mod+Shift+X Swaylock fallback
```

Fallback مستقل مهم است: اگر shell UI مشکل داشت، lock screen دوم وجود دارد.

Suspend/lid policy در NixOS laptop module است؛ lock-before-suspend را با خود suspend یکی ندانید. رفتار نهایی Noctalia/logind باید روی سخت‌افزار واقعی تست شود.

---

# troubleshooting سریع

## Noctalia پاسخ نمی‌دهد

```bash
systemctl --user status noctalia-shell.service
journalctl --user -u noctalia-shell.service -b --no-pager
```

نام دقیق unit را در output Home Manager بررسی کنید؛ source module می‌تواند نام را تغییر دهد.

## keybinding کار نمی‌کند

1. `docs/keys.md` را با `config.kdl` مقایسه کنید؛
2. hotkey overlay را باز کنید؛
3. conflict application-level را بررسی کنید؛
4. برای Caps رفتار keyd را جدا از Niri بررسی کنید.

## application backend اشتباه دارد

```bash
WAYLAND_DEBUG=1 application 2>wayland.log
```

این output بسیار verbose است؛ فقط برای reproduction کوتاه استفاده شود و قبل از انتشار، path/clipboard data بازبینی شود.

---

مرجع کامل shortcutها: [keys.md](keys.md)

بعدی: [۰۶ Neovim](06-editor.md)
