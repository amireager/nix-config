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
| Region / screen / window screenshot | `Mod+P` / `Mod+Shift+P` / `Mod+Alt+P` | niri: فایل در `XDG_SCREENSHOTS_DIR` و clipboard |
| Region screenshot → clipboard | `Mod+Ctrl+P` | Slurp → Grim → wl-copy |
| Record toggle/GUI | `Mod+Alt+R` | GPU Screen Recorder GTK |
| Keycaster | `Mod+Alt+K` | wshowkeys |

فایل screenshotهای niri در `screenshot-path` ذخیره می‌شود. `config.kdl` آن را از `xdg.userDirs.extraConfig.SCREENSHOTS` پر می‌کند (پیش‌فرض ما `~/media/img/screenshots`). niri خودش `~/Pictures/Screenshots` را فرض می‌کند و `user-dirs.dirs` را نمی‌خواند؛ بدون این خط، با عوض‌شدن `pictures` هم screenshot به پوشه‌ی قدیمی می‌رفت. `Mod+Ctrl+P` فایل نمی‌سازد و فقط در clipboard می‌گذارد.

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

# پوشه‌های home

چیدمان `~` فقط در `modules/home/gui/xdg.nix` (`xdg.userDirs`) تعیین می‌شود:

| پوشه | کلید در `user-dirs.dirs` | کاربرد |
| :--- | :--- | :--- |
| `~/dev` | `XDG_PROJECTS_DIR` | پروژه‌ها؛ `<leader>fp` در Neovim اینجا را می‌گردد |
| `~/dl` | `XDG_DOWNLOAD_DIR` | دانلود |
| `~/doc` | `XDG_DOCUMENTS_DIR` | اسناد (`~/doc/templates` = `XDG_TEMPLATES_DIR`) |
| `~/dsk` | `XDG_DESKTOP_DIR` | Desktop |
| `~/media/img` | `XDG_PICTURES_DIR` | تصویر |
| `~/media/img/screenshots` | `XDG_SCREENSHOTS_DIR` | screenshotهای niri و Noctalia |
| `~/media/img/wallpapers` | `XDG_WALLPAPERS_DIR` | wallpaperهای Noctalia |
| `~/media/audio` | `XDG_MUSIC_DIR` | موسیقی |
| `~/media/vid` | `XDG_VIDEOS_DIR` | ویدیو و ضبط‌های gpu-screen-recorder |
| `~/pub` | `XDG_PUBLICSHARE_DIR` | اشتراک عمومی |

بعد از هر switch دقیقاً همین پوشه‌ها ساخته می‌شوند (`createDirectories`) و `~/Projects`، `~/Pictures` و مانند آن‌ها دیگر ساخته نمی‌شوند. مسیر را در shell با `xdg-user-dir SCREENSHOTS` (یا `DOWNLOAD`، `PROJECTS`، …) می‌گیرید و در Nix با `config.xdg.userDirs`.

## قاعده‌ها

1. برنامه یا scriptی که چیزی داخل `~` می‌نویسد، مسیرش را از `config.xdg.userDirs` بگیرد؛ `~/Pictures`، `~/Downloads` یا `~/projects` را hard-code نکنید. بیشتر برنامه‌های GTK/Qt و مرورگرها `user-dirs.dirs` را خودشان می‌خوانند و کار اضافه نمی‌خواهند.
2. `xdg.userDirs.projects` را همیشه صریح بنویسید. Home Manager برایش پیش‌فرض `~/Projects` می‌گذارد و `createDirectories` آن را در هر switch دوباره می‌سازد، حتی وقتی ما `~/dev` را داریم.
3. با `home.stateVersion >= 26.05` کلید `extraConfig` همان نام ساده است (`SCREENSHOTS`)، نه `XDG_SCREENSHOTS_DIR`؛ با پیشوند و پسوند به `XDG_XDG_..._DIR_DIR` تبدیل می‌شود.
4. Home Manager فقط می‌سازد و هیچ‌وقت پاک نمی‌کند: بعد از عوض‌کردن چیدمان، پوشه‌ی قدیمی می‌ماند.

## برنامه‌هایی که XDG را نمی‌خوانند

| برنامه | پیش‌فرض خودش | وضعیت |
| :--- | :--- | :--- |
| niri | `~/Pictures/Screenshots` | `screenshot-path` در `config.kdl` از `SCREENSHOTS` پر می‌شود |
| Noctalia | نسخه‌ی 5.0: wallpaper در `~/Pictures/Wallpapers` و screenshot در `~/Pictures`؛ از 5.3 هر دو از `XDG_PICTURES_DIR` | `wallpaper.directory` و `shell.screenshot.directory` پر می‌شوند تا زیرپوشه‌ها روی هر دو نسخه یکی باشد |
| mpv | screenshot در پوشه‌ی اجرای mpv، و از لانچر در `XDG_DESKTOP_DIR` | عمداً دست‌نخورده |
| guvcview | عکس و ویدیو مستقیم داخل `~` | یک بار در تنظیمات خود برنامه عوض کنید |
| Go | `GOPATH=~/go`، پوشه‌ی دیده‌شونده در `~` | دست‌نخورده؛ برای جابه‌جایی `GOPATH` را در `shells/go` به `$XDG_DATA_HOME/go` ببرید |
| gpu-screen-recorder | مسیر ذخیره را از `XDG_VIDEOS_DIR` می‌خواند | درست است؛ مسیری که قبلاً در خود برنامه ذخیره شده بماند |

## انتقال از چیدمان قدیمی

```bash
# چه چیزی از چیدمان قدیمی مانده؟
ls -d ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos ~/Projects ~/projects 2>/dev/null

# محتوا را ببرید؛ mv -n هیچ فایلی را overwrite نمی‌کند
mv -n ~/Pictures/Screenshots/* ~/media/img/screenshots/
mv -n ~/Downloads/* ~/dl/

# rmdir فقط پوشه‌ی خالی را پاک می‌کند، پس امن است
rmdir ~/Pictures/Screenshots ~/Pictures ~/Downloads
```

`*` فایل‌های مخفی را نمی‌گیرد؛ پیش از `rmdir` با `ls -A` بررسی کنید. تنظیمی که خود برنامه ذخیره کرده (مسیر دانلود مرورگر، مسیر ضبط gpu-screen-recorder، bookmark در Thunar) را هم یک بار باید از داخل همان برنامه عوض کنید.

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

وقتی layout فارسی است، keyهای command-mode به معادل حرکتی لاتین map می‌شوند تا برای حرکت کوتاه مجبور به تعویض layout نباشید. Insert mode همچنان متن فارسی عادی می‌نویسد. ارقام فارسی (`۱`–`۹`، `۰`) هم به رقم لاتین map می‌شوند، پس count مثل `۳یی` (= `3dd`) بدون تعویض layout کار می‌کند.

دو نکته هنگام ویرایش `opt.langmap` در `options.lua`: ‏`,` و `;` به‌عنوان مقصد باید escape شوند (`\,` و `\;`)، و هر جفت واقعاً key را برای همیشه عوض می‌کند. جفتی که شبیه identity است (مثل `./`) در عمل `.` را به `/` تبدیل می‌کرد و dot-repeat را به یک search prompt بدل می‌کرد؛ کلیدهای `.` و `/` روی layout فارسی همان `.` و `/` را می‌دهند و ورودی لازم ندارند. لایه‌ی Shift هم map شده است: `Q W E R T Y U I A S D F G H J K L Z X C V N M` و `$ % ^ @ # & _ ~ " ?` زیر layout فارسی کار می‌کنند. تمام جفت‌ها از فایل `symbols/ir` در xkeyboard-config (layout استاندارد ISIRI 9147) گرفته شده‌اند؛ حروف با mapping دستی قبلی یکسان بودند و ارقام و لایه‌ی Shift از همان فایل اضافه شدند. این کلیدها قابل map نیستند: `O` و `P` و `( )` و `< >`، چون خود layout یک کاراکتر ASCII می‌دهد (`O` و `P` روی layout فارسی `]` و `[` تایپ می‌شوند و `( )` و `< >` نسبت به لاتین جابه‌جا هستند)، و `B` که یک ZWNJ نامرئی تایپ می‌کند؛ برای این‌ها به layout لاتین برگردید. آرگومان `f`/`t`/`r` دست‌نخورده می‌ماند، پس `fا` همچنان حرف فارسی را پیدا می‌کند و `rا` همان را جایگزین می‌کند.

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
