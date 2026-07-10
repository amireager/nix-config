# 🛠️ ابزارهای CLI — جایگزین‌های مدرن

## فایل و دیسک

### duf

جایگزین مدرن `df`. نمایش فضای دیسک با رنگ و خوانایی بالا.

```bash
duf                 # نمایش همه فایل‌سیستم‌ها
duf /home           # نمایش یک مسیر خاص
duf --json          # خروجی JSON
```

### erdtree

نمایش درخت دایرکتوری با اندازه فایل‌ها. سریع‌تر از `du` و `tree`.

```bash
erd                 # نمایش درخت با اندازه
erd -l 2            # محدود به عمق 2
erd -H              # شامل فایل‌های مخفی
erd --sort size     # مرتب‌سازی بر اساس اندازه
```

### fd

جایگزین سریع `find`. جستجوی فایل و دایرکتوری.

```bash
fd "pattern"        # جستجوی نام فایل
fd -e py            # فقط پسوند .py
fd -t f             # فقط فایل‌ها
fd -t d             # فقط دایرکتوری‌ها
fd -H               # شامل مخفی‌ها
fd -s "Pattern"     # case-sensitive
fd --changed-within 1d  # تغییریافته در 24 ساعت اخیر
```

### eza

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

### yazi

فایل منیجر TUI با پیش‌نمایش فایل.

```bash
y                   # باز کردن yazi (alias)
y /path             # باز کردن در مسیر خاص
```

**میانبرها:**

| میانبر | عملکرد |
|---|---|
| `h/j/k/l` | ناوبری (vim-style) |
| `Enter` | باز کردن |
| `q` | خروج |
| `~` | خانه |
| `.` | فایل‌های مخفی |
| `z` | جستجوی fuzzy (zoxide) |
| `/` | جستجو |
| `Space` | انتخاب |
| `y` | کپی |
| `x` | برش |
| `p` | پیست |
| `d` | حذف |
| `a` | ساختن |
| `r` | تغییر نام |

### glow

رندر Markdown در ترمینال.

```bash
glow README.md      # نمایش Markdown
glow .              # نمایش فایل‌های md در دایرکتوری
glow -p README.md   # حالت pager
```

---

## متن و جستجو

### bat

جایگزین `cat` با syntax highlighting، line numbers، و git integration.

```bash
cat file.py         # alias → bat با syntax highlighting
bat file.py         # مستقیم
bat --style=plain   # بدون line numbers (برای پایپ)
bat -l json         # اجبار زبان syntax
bat -r 10:20        # فقط خطوط 10 تا 20
```

### ripgrep (rg)

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

### jq

پردازنده JSON برای خط فرمان.

```bash
echo '{"name":"amir"}' | jq '.name'
# → "amir"

cat data.json | jq '.items[] | .name'
# → لیست نام‌ها

curl api.github.com | jq '.login'
# → استخراج فیلد از API
```

### sd

جایگزین ساده `sed` برای جایگذاری متن.

```bash
sd 'old' 'new' file.txt    # جایگذاری در فایل
echo "hello" | sd 'o' '0'  # در پایپ
```

---

## مانیتورینگ سیستم

### btop

مانیتور سیستم زیبا. جایگزین htop.

```bash
btop                # باز کردن btop (alias: top)
```

**میانبرها:**

| میانبر | عملکرد |
|---|---|
| `1-4` | سوییچ بین نماها |
| `m` | نمایش حافظه |
| `p` | نمایش پردازنده |
| `n` | نمایش شبکه |
| `d` | نمایش دیسک |
| `q` | خروج |

### fastfetch

نمایش اطلاعات سیستم (مثل neofetch ولی سریع‌تر).

```bash
fastfetch           # نمایش اطلاعات سیستم
```

### iotop

نمایش مصرف دیسک به ازای هر پردازش.

```bash
sudo iotop          # نمایش I/O پردازش‌ها
```

### procs

جایگزین رنگی `ps`.

```bash
procs               # لیست پردازش‌ها
procs firefox       # فیلتر بر اساس نام
procs --tree        # درخت پردازش‌ها
```

### bandwhich

نمایش مصرف شبکه به ازای هر پردازش.

```bash
sudo bandwhich      # نمایش مصرف شبکه
```

---

## شبکه و انتقال

### xh

جایگزین مدرن `curl` و `httpie`.

```bash
xh GET api.github.com/users/amir
xh POST api.example.com name=amir age:=25
xh PUT api.example.com/1 name=amir
xh DELETE api.example.com/1
```

### rsync

همگام‌سازی فایل‌ها.

```bash
rsync -avz src/ dest/              # همگام‌سازی
rsync -avz --delete src/ dest/     # با حذف فایل‌های اضافی
rsync -avz src/ user@host:/path/   # از راه دور
```

---

## داده و فرمت

### hexyl

نمایش فایل‌ها به صورت hex.

```bash
hexyl file.bin              # نمایش hex
hexyl --length 256 file.bin # فقط 256 بایت
```

### file

تشخیص نوع فایل.

```bash
file document.pdf   # تشخیص نوع
file *              # تشخیص همه فایل‌ها
```

### grex

ساخت regex از مثال‌ها.

```bash
grex a b c          # → [a-c]
grex 192.168.1.1    # → \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}
```

### tailspin

نمایش لاگ‌ها با highlighting خودکار.

```bash
tailspin /var/log/syslog        # نمایش لاگ
journalctl | tailspin           # از پایپ
tailspin -f /var/log/app.log    # follow (مثل tail -f)
```

---

## بهره‌وری و توسعه

### lazygit

رابط TUI برای git.

```bash
lazygit             # باز کردن lazygit
```

**میانبرها:**

| میانبر | عملکرد |
|---|---|
| `1-5` | سوییچ پنل |
| `Space` | stage/unstage |
| `c` | commit |
| `P` | push |
| `p` | pull |
| `e` | edit file |
| `o` | باز کردن در مرورگر |
| `q` | خروج |

### navi

چیت‌شیت تعاملی. دستورات رایج بدون حفظ کردن.

```bash
navi                # باز کردن navi
navi --print        # فقط نمایش دستور
```

### hyperfine

ベンチمارک دستورات خط فرمان.

```bash
hyperfine 'sleep 0.3'
hyperfine 'fd' 'find . -name "*"'  # مقایسه
hyperfine --warmup 3 'command'
```

### just

جایگزین مدرن `make`.

```bash
just                # لیست دستورات
just build          # اجرای build
just test           # اجرای تست
```

### gh-dash

داشبورد TUI برای GitHub.

```bash
gh-dash             # باز کردن داشبورد
```

### tokei

شمارش خطوط کد بر اساس زبان.

```bash
tokei               # شمارش در دایرکتوری فعلی
tokei --sort lines  # مرتب‌سازی بر اساس تعداد خطوط
```

### watchexec

اجرای خودکار دستور هنگام تغییر فایل.

```bash
watchexec -e py python main.py      # اجرا هنگام تغییر .py
watchexec -e rs cargo test           # اجرا هنگام تغییر .rs
watchexec --clear cargo run          # پاک کردن صفحه قبل از اجرا
```

### difftastic

مقایسه هوشمند فایل‌ها با درک syntax.

```bash
difft old.py new.py         # مقایسه دو فایل
git difftool --difftool=difft  # استفاده با git
```

### tealdeer (tldr)

خلاصه دستورات.

```bash
tldr tar            # خلاصه دستور tar
tldr git commit     # خلاصه git commit
```
