# 🎬 Media — mpv، imv، zathura، playerctl

## mpv

پخش‌کننده ویدیو و صوت سبک و قدرتمند.

```bash
mpv video.mp4                   # پخش ویدیو
mpv audio.mp3                   # پخش صوت
mpv https://youtube.com/watch?v=...  # پخش از URL
mpv --fullscreen video.mp4      # تمام صفحه
mpv --loop video.mp4            # تکرار
mpv --speed 1.5 video.mp4      # سرعت 1.5x
```

### میانبرها (حین پخش)

| میانبر | عملکرد |
|---|---|
| `Space` | pause/play |
| `Left/Right` | عقب/جلو 5 ثانیه |
| `Up/Down` | عقب/جلو 60 ثانیه |
| `[/]` | کاهش/افزایش سرعت |
| `f` | toggle fullscreen |
| `m` | mute |
| `9/0` | کاهش/افزایش صدا |
| `s` | اسکرین‌شات |
| `q` | خروج |
| `o` | نمایش OSD |
| `i` | نمایش اطلاعات فایل |
| `j/J` | سوییچ زیرنویس |
| `#/` | سوییچ صوت |

### تنظیمات

پخش‌کننده پیش‌فرض برای: mp4, mkv, webm, mpeg, flac

---

## imv

نمایشگر تصویر سبک برای Wayland.

```bash
imv image.png                   # نمایش تصویر
imv *.png                       # نمایش چند تصویر
imv -f directory/               # نمایش تمام تصاویر دایرکتوری
```

### میانبرها

| میانبر | عملکرد |
|---|---|
| `j/k` | تصویر قبلی/بعدی |
| `q` | خروج |
| `f` | fullscreen |
| `r` | چرخش |
| `+/-` | زوم |
| `c` | center |
| `w` | fit to window |
| `a` | fit to actual size |

**تنظیمات:** نمایشگر پیش‌فرض برای: png, jpeg, gif, webp

---

## zathura

نمایشگر PDF vim-style.

```bash
zathura document.pdf            # باز کردن PDF
```

### میانبرها

| میانبر | عملکرد |
|---|---|
| `j/k` | اسکرول |
| `h/l` | اسکرول افقی |
| `J/K` | صفحه بعدی/قبلی |
| `gg/G` | اول/آخر |
| `/` | جستجو |
| `n/N` | تطابق بعدی/قبلی |
| `+/-` | زوم |
| `W` | عرض صفحه |
| `a` | اندازه واقعی |
| `s` | ذخیره snapshot |
| `p` | ارائه |
| `d` | حالت دو صفحه |
| `F` | fullscreen |
| `R` | چرخش |
| `r` | ریلود |
| `q` | خروج |

**تنظیمات:** نمایشگر پیش‌فرض برای PDF

---

## playerctl

کنترل پخش رسانه از ترمینال.

```bash
playerctl play                  # پخش
playerctl pause                 # توقف
playerctl play-pause            # toggle
playerctl next                  # بعدی
playerctl previous              # قبلی
playerctl volume 0.5            # تنظیم صدا
playerctl volume 0.1+           # افزایش
playerctl status                # وضعیت
playerctl metadata              # اطلاعات آهنگ
playerctl metadata title        # عنوان
playerctl metadata artist       # هنرمند
```

### استفاده با پردازش‌های خاص

```bash
playerctl -p spotify play       # فقط Spotify
playerctl -p mpv pause          # فقط mpv
playerctl -l                    # لیست پردازش‌های فعال
```

---

## poppler-utils

ابزارهای CLI برای PDF.

```bash
pdftotext document.pdf output.txt    # تبدیل PDF به متن
pdfinfo document.pdf                 # اطلاعات PDF
pdfimages document.pdf img           # استخراج تصاویر
pdftohtml document.pdf output.html   # تبدیل به HTML
pdffonts document.pdf                # لیست فونت‌ها
```

---

## ffmpegthumbnailer

ساخت بندانگشتی (thumbnail) از ویدیو. توسط Thunar و سایر فایل منیجرها استفاده می‌شود.

```bash
# خودکار توسط فایل منیجر استفاده می‌شود
ffmpegthumbnailer -i video.mp4 -o thumb.png -s 256
```

---

## udiskie

اتومات mount کردن USB drives.

```bash
# خودکار اجرا می‌شود — USB را وصل کنید، mount می‌شود
udiskie -t                      # با tray icon
udiskie --no-automount          # فقط notification
```

---

## فایل‌های فشرده

### zip / unzip

```bash
zip archive.zip file1 file2     # ساخت zip
zip -r archive.zip directory/   # zip recursive
unzip archive.zip               # استخراج
unzip archive.zip -d /path/    # استخراج در مسیر
```

### p7zip (7z)

```bash
7z a archive.7z file1 file2    # ساخت 7z
7z x archive.7z                 # استخراج
```

### unrar

```bash
unrar x archive.rar             # استخراج
unrar l archive.rar             # لیست فایل‌ها
```
