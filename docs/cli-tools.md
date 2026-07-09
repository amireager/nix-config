# 🛠️ CLI Tools — ابزارهای خط فرمان

## eza

جایگزین مدرن `ls` با آیکون، git integration، و tree view.

```bash
ls                  # لیست با آیکون و ترتیب دایرکتوری
ll                  # لیست با جزئیات + git status
la                  # شامل فایل‌های مخفی
lt                  # درخت دایرکتوری (عمق 2)
tree                # درخت کامل
eza --git -l        # جزئیات + git
eza --icons         # فقط آیکون‌ها
```

---

## bat

جایگزین `cat` با syntax highlighting، line numbers، و git integration.

```bash
cat file.py         # alias → bat با syntax highlighting
bat file.py         # مستقیم
bat --style=plain   # بدون line numbers (برای پایپ)
bat -l json         # اجبار زبان syntax
bat -r 10:20        # فقط خطوط 10 تا 20
```

**تنظیمات:** theme ansi، line numbers + changes + header.

---

## ripgrep (rg)

جایگزین سریع `grep`. جستجوی recursive در فایل‌ها.

```bash
grep "pattern" .    # alias → ripgrep
rg "TODO"           # جستجوی recursive
rg -i "error"       # case-insensitive
rg -t py "import"   # فقط فایل‌های Python
rg --hidden "key"   # شامل فایل‌های مخفی
rg -l "pattern"     # فقط نام فایل‌ها
rg -c "pattern"     # تعداد تطابق‌ها
rg -A 2 -B 2 "err"  # 2 خط قبل و بعد
```

---

## fd

جایگزین سریع `find`. جستجوی فایل و دایرکتوری.

```bash
find "*.txt"        # alias → fd
fd "pattern"        # جستجوی نام فایل
fd -e py            # فقط پسوند .py
fd -t f             # فقط فایل‌ها
fd -t d             # فقط دایرکتوری‌ها
fd -H               # شامل مخفی‌ها
fd -s "Pattern"     # case-sensitive
fd --changed-within 1d  # تغییریافته در 24 ساعت اخیر
```

---

## jq

پردازنده JSON برای خط فرمان.

```bash
echo '{"name":"amir","age":25}' | jq '.name'
# → "amir"

cat data.json | jq '.items[] | .name'
# → لیست نام‌ها

curl api.github.com | jq '.login'
# → استخراج فیلد از API

echo '{"a":1,"b":2}' | jq '.a + .b'
# → 3
```

---

## yazi

فایل منیجر TUI با پیش‌نمایش فایل.

```bash
y                   # باز کردن yazi (alias)
y /path             # باز کردن در مسیر خاص
```

### میانبرها

| میانبر    | عملکرد                |
| --------- | --------------------- |
| `h/j/k/l` | ناوبری (vim-style)    |
| `Enter`   | باز کردن              |
| `q`       | خروج                  |
| `~`       | خانه                  |
| `.`       | فایل‌های مخفی         |
| `z`       | جستجوی fuzzy (zoxide) |
| `Z`       | cd تعاملی             |
| `/`       | جستجو                 |
| `n`       | تطابق بعدی            |
| `Space`   | انتخاب                |
| `y`       | کپی                   |
| `x`       | برش                   |
| `p`       | پیست                  |
| `d`       | حذف                   |
| `a`       | ساختن                 |
| `r`       | تغییر نام             |

---

## btop

مانیتور سیستم زیبا. جایگزین htop.

```bash
btop                # باز کردن btop (alias: top)
```

### میانبرها

| میانبر | عملکرد          |
| ------ | --------------- |
| `1-4`  | سوییچ بین نماها |
| `m`    | نمایش حافظه     |
| `p`    | نمایش پردازنده  |
| `n`    | نمایش شبکه      |
| `d`    | نمایش دیسک      |
| `q`    | خروج            |

---

## fastfetch

نمایش اطلاعات سیستم (مثل neofetch ولی سریع‌تر).

```bash
fastfetch           # نمایش اطلاعات سیستم
fastfetch --logo none  # بدون لوگو
```

---

## lazygit

رابط TUI برای git. مدیریت ریپو بدون تایپ دستورات git.

```bash
lazygit             # باز کردن lazygit
```

### میانبرها

| میانبر  | عملکرد             |
| ------- | ------------------ |
| `1-5`   | سوییچ پنل          |
| `Space` | stage/unstage      |
| `c`     | commit             |
| `P`     | push               |
| `p`     | pull               |
| `e`     | edit file          |
| `o`     | باز کردن در مرورگر |
| `q`     | خروج               |

---

## tealdeer (tldr)

خلاصه دستورات (جایگزین `man` برای موارد رایج).

```bash
tldr tar            # خلاصه دستور tar
tldr git commit     # خلاصه git commit
tldr docker         # خلاصه docker
```

---

## broot

درخت دایرکتوری تعاملی با قابلیت جستجو.

```bash
br                  # باز کردن broot
br -s               # با جستجوی اولیه
```

---

## grc

رنگ‌بندی خودکار خروجی دستورات.

```bash
# خودکار فعال — خروجی ping, netstat, etc. رنگی می‌شود
```

---

## dust

نمایش مصرف دیسک به صورت درختی.

```bash
dust                # نمایش مصرف دیسک
dust -n 10          # فقط 10 مورد بزرگ
dust -d 3           # عمق 3
```

---

## procs

جایگزین رنگی `ps`.

```bash
procs               # لیست پردازش‌ها
procs firefox       # فیلتر بر اساس نام
procs --tree        # درخت پردازش‌ها
```

---

## bandwhich

نمایش مصرف شبکه به ازای هر پردازش.

```bash
sudo bandwhich      # نمایش مصرف شبکه
```

---

## iotop

نمایش مصرف دیسک به ازای هر پردازش.

```bash
sudo iotop          # نمایش I/O پردازش‌ها
```

---

## hyperfine

ベンチمارک دستورات خط فرمان.

```bash
hyperfine 'sleep 0.3'           #ベンチمارک یک دستور
hyperfine 'fd' 'find . -name "*"'  # مقایسه دو دستور
hyperfine --warmup 3 'command'  # با warmup
```

---

## just

جایگزین مدرن `make`. اجرای دستورات تعریف‌شده.

```bash
just                # لیست دستورات
just build          # اجرای دستور build
just test           # اجرای تست
just deploy         # دیپلوی
```

**مثال `justfile`:**

```just
build:
    cargo build --release

test:
    cargo test

deploy: build
    rsync -avz target/release/app server:/opt/
```

---

## watchexec

اجرای خودکار دستور هنگام تغییر فایل.

```bash
watchexec -e py python main.py      # اجرا هنگام تغییر .py
watchexec -e rs cargo test           # اجرا هنگام تغییر .rs
watchexec -w src -e ts npm run build # watch فقط src/
watchexec --clear cargo run          # پاک کردن صفحه قبل از اجرا
```

---

## tokei

شمارش خطوط کد بر اساس زبان.

```bash
tokei               # شمارش در دایرکتوری فعلی
tokei /path/to/dir  # شمارش در مسیر خاص
tokei --sort lines  # مرتب‌سازی بر اساس تعداد خطوط
```

---

## difftastic

مقایسه هوشمند فایل‌ها با درک syntax.

```bash
difft old.py new.py         # مقایسه دو فایل
git difftool --difftool=difft  # استفاده با git
```

**کاربرد:** نمایش تفاوت‌ها بر اساس ساختار کد، نه خط به خط.

---

## sd

جایگزین ساده `sed` برای جایگذاری متن.

```bash
sd 'old' 'new' file.txt    # جایگذاری در فایل
echo "hello" | sd 'o' '0'  # در پایپ
```

---

## xh

جایگزین مدرن `curl` و `httpie`.

```bash
xh GET api.github.com/users/amir
xh POST api.example.com name=amir age:=25
xh PUT api.example.com/1 name=amir
xh DELETE api.example.com/1
```

---

## hexyl

نمایش فایل‌ها به صورت hex.

```bash
hexyl file.bin              # نمایش hex
hexyl --length 256 file.bin # فقط 256 بایت
```

---

## tailspin

نمایش لاگ‌ها با highlighting خودکار.

```bash
tailspin /var/log/syslog        # نمایش لاگ
journalctl | tailspin           # از پایپ
tailspin -f /var/log/app.log    # follow (مثل tail -f)
```

---

## navi

چیت‌شیت تعاملی. دستورات رایج را بدون حفظ کردن اجرا کنید.

```bash
navi                # باز کردن navi
navi --print        # فقط نمایش دستور (بدون اجرا)
```

---

## rsync

همگام‌سازی فایل‌ها.

```bash
rsync -avz src/ dest/              # همگام‌سازی
rsync -avz --delete src/ dest/     # با حذف فایل‌های اضافی
rsync -avz src/ user@host:/path/   # از راه دور
```

---

## gh-dash

داشبورد TUI برای GitHub.

```bash
gh-dash             # باز کردن داشبورد
```

**نمایش:** PRها، issueها، نوتیفیکیشن‌ها، و workflowها.
