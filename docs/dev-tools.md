# 🧰 Dev Tools — ابزارهای توسعه

## nixd

Language Server Protocol (LSP) برای زبان Nix. ارائه autocomplete، diagnostics، و hover در ادیتور.

```bash
# خودکار در Neovim فعال — وقتی فایل .nix باز کنید:
# - autocomplete برای attribute names
# - diagnostics برای خطاها
# - hover برای documentation
# - go-to-definition
```

**کاربرد:** توسعه راحت‌تر فایل‌های Nix در Neovim.

---

## nix-tree

نمایش درخت وابستگی‌ها در ترمینال.

```bash
nix-tree nixpkgs#firefox    # وابستگی‌های firefox
nix-tree .#nixosConfigurations.nixos.config.system.build.toplevel  # وابستگی‌های سیستم
```

**کاربرد:** فهمیدن اینکه یک پکیج چه چیزهایی را نصب می‌کند و حجم آن‌ها.

---

## nvd

مقایسه دو نسل NixOS.

```bash
nvd diff /run/current-system ./result
```

**خروجی:**
```
Version changes:
[C.]  #1  firefox  128.0 -> 129.0
[U.]  #2  nixos-system  26.05.abc -> 26.05.def
[A.]  #3  new-package  1.0.0
[R.]  #4  old-package  2.0.0
```

**کاربرد:** قبل از `switch`، ببینید چه چیزی تغییر می‌کند.

---

## nix-search-tv

جستجوی پکیج‌ها با رابط TUI.

```bash
nix-search-tv firefox       # جستجوی firefox
nix-search-tv "text editor" # جستجوی عبارت
```

**کاربرد:** پیدا کردن نام دقیق پکیج در nixpkgs.

---

## comma (,)

اجرای هر دستوری بدون نصب.

```bash
, cowsay hello          # اجرا بدون نصب cowsay
, speedtest             # اجرا بدون نصب speedtest
, ffmpeg -version       # اجرا بدون نصب ffmpeg
```

**نیاز به:** `nix-index` (ایندکس پکیج‌ها)

**کاربرد:** امتحان کردن ابزارها قبل از نصب دائمی.

---

## nix-index

ایندکس تمام پکیج‌های nixpkgs.

```bash
nix-index               # ساخت/آپدیت ایندکس
nix-locate libstdc++.so # جستجوی فایل در پکیج‌ها
nix-locate --top-level  # فقط پکیج‌های اصلی
```

**کاربرد:** پیدا کردن اینکه کدام پکیج یک فایل خاص را ارائه می‌دهد.

---

## tokei

شمارش خطوط کد بر اساس زبان.

```bash
tokei                   # شمارش در دایرکتوری فعلی
tokei /path/to/project  # شمارش در مسیر خاص
tokei --sort lines      # مرتب‌سازی بر اساس تعداد خطوط
tokei --files           # نمایش فایل‌ها
```

**خروجی:**
```
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
 Rust                   42         8500         6800          800          900
 Nix                    15         1200          900          150          150
 Lua                    12          800          600          100          100
===============================================================================
 Total                  69        10500         8300         1050         1150
===============================================================================
```

---

## watchexec

اجرای خودکار دستور هنگام تغییر فایل.

```bash
watchexec -e py python main.py       # اجرا هنگام تغییر فایل .py
watchexec -e rs cargo test            # اجرا هنگام تغییر فایل .rs
watchexec -w src -e ts npm run build  # watch فقط دایرکتوری src/
watchexec --clear cargo run           # پاک کردن صفحه قبل از هر اجرا
watchexec -n cargo test               # بدون debounce (فوری)
```

**کاربرد:** توسعه سریع — فایل را ذخیره کنید، تست خودکار اجرا می‌شود.

---

## difftastic

مقایسه هوشمند فایل‌ها با درک syntax.

```bash
difft old.py new.py                    # مقایسه دو فایل
difft old.rs new.rs                    # مقایسه Rust
git difftool --no-prompt --extcmd=difft  # استفاده با git
```

**خروجی:** تفاوت‌ها بر اساس ساختار کد نمایش داده می‌شود، نه خط به خط.

**کاربرد:** درک بهتر تغییرات در code review.

---

## hyperfine

ベンチمارک دستورات خط فرمان.

```bash
hyperfine 'sleep 0.3'                     #ベンチمارک یک دستور
hyperfine 'fd' 'find . -name "*"'         # مقایسه دو دستور
hyperfine --warmup 3 'command'            # با warmup
hyperfine --runs 100 'command'            # 100 بار اجرا
hyperfine --export-json results.json 'cmd'  # خروجی JSON
```

**خروجی:**
```
Benchmark 1: fd
  Time (mean ± σ):      12.3 ms ±   0.5 ms    [User: 8.2 ms, System: 4.1 ms]
  Range (min … max):    11.5 ms …  14.2 ms    200 runs

Benchmark 2: find . -name "*"
  Time (mean ± σ):      85.2 ms ±   2.1 ms    [User: 45.3 ms, System: 39.9 ms]
  Range (min … max):    82.1 ms …  92.5 ms    50 runs
```

---

## just

جایگزین مدرن `make`. اجرای دستورات تعریف‌شده.

```bash
just                # لیست دستورات موجود
just build          # اجرای دستور build
just test           # اجرای تست
just deploy         # دیپلوی
just --list         # لیست با توضیحات
```

**مثال `justfile`:**
```just
# ساخت پروژه
build:
    cargo build --release

# اجرای تست‌ها
test:
    cargo test

# فرمت کد
fmt:
    cargo fmt

# لینت کد
lint:
    cargo clippy

# دیپلوی (بعد از build)
deploy: build
    rsync -avz target/release/app server:/opt/

# پاک‌سازی
clean:
    cargo clean
```

---

## gh-dash

داشبورد TUI برای GitHub.

```bash
gh-dash             # باز کردن داشبورد
```

**نمایش:**
- PRهای باز شما
- Issueهای اختصاص‌داده شده
- نوتیفیکیشن‌ها
- GitHub Actions workflowها

---

## sd

جایگزین ساده `sed` برای جایگذاری متن.

```bash
sd 'old' 'new' file.txt          # جایگذاری در فایل
echo "hello" | sd 'o' '0'        # در پایپ
sd '(\w+)' '$1.md' file.txt     # regex
sd -f all 'old' 'new' file.txt  # همه تطابق‌ها
```

---

## xh

جایگزین مدرن `curl` و `httpie`.

```bash
xh GET api.github.com/users/amir
xh POST api.example.com name=amir age:=25
xh PUT api.example.com/1 name=amir
xh DELETE api.example.com/1
xh --headers api.example.com     # فقط headers
xh --body api.example.com        # فقط body
```

---

## grex

ساخت regex از مثال‌ها.

```bash
grex a b c              # → [a-c]
grex 192.168.1.1        # → \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}
grex -e "test" "text"   # → te[st]x
```

---

## navi

چیت‌شیت تعاملی.

```bash
navi                # باز کردن navi
navi --print        # فقط نمایش دستور
navi --tldr docker  # از tldr
```

**کاربرد:** اجرای دستورات پیچیده بدون حفظ کردن.
