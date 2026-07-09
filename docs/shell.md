# 🐚 Shell — Fish، Starship، و ابزارهای شل

## Fish Shell

شل تعاملی مدرن. جایگزین bash/zsh با auto-suggestions، syntax highlighting، و completions داخلی.

```bash
# ویرایش فایل با nvim (alias)
n filename

# ناوبری هوشمند (zoxide)
z project-name      # cd هوشمند
zi                  # interactive cd با fzf

# تاریخچه هوشمند (atuin)
Ctrl-R              # جستجوی تاریخچه

# فایل منیجر TUI
y                   # yazi

# alias‌های مهم
ls                  # eza با آیکون
ll                  # لیست با جزئیات
la                  # شامل فایل‌های مخفی
lt                  # درخت دایرکتوری
cat                 # bat با syntax highlighting
grep                # ripgrep
find                # fd
top                 # btop
```

**تنظیمات:** رنگ‌ها Catppuccin Mocha، greeting غیرفعال، default editor = nvim.

---

## Starship

پرامپت سریع و زیبا برای هر شلی.

**نمایش:**
- مسیر فعلی (آبی)
- شاخه git (نارنجی)
- وضعیت git (قرمز: تغییرات، سبز: تمیز)
- nix shell (برفی ❄️)
- مدت زمان اجرای دستور (زرد)

```bash
# تنظیمات در fish.nix تعریف شده — نیازی به دستور خاصی نیست
# فقط مطمئن شوید programs.starship.enable = true است
```

**کاربرد:** نمایش اطلاعات مفید در پرامپت بدون کاهش سرعت.

---

## Zoxide

جایگزین هوشمند `cd`. مسیرهای پرکاربرد را یاد می‌گیرد.

```bash
# cd هوشمند (بعد از چند بار استفاده)
z project           # cd ~/Documents/projects/my-project
z downloads         # cd ~/Downloads

# انتخاب تعاملی با fzf
zi

# افزودن مسیر دستی
zoxide add /path/to/dir

# حذف مسیر
zoxide remove /path/to/dir
```

**کاربرد:** ناوبری سریع بین دایرکتوری‌ها بدون تایپ کامل مسیر.

---

## Direnv

بارگذاری خودکار محیط‌های توسعه هنگام ورود به دایرکتوری.

```bash
# فعال‌سازی خودکار — وقتی وارد پروژه‌ای با .envrc شوید:
cd my-project
# → محیط خودکار بارگذاری می‌شود (PATH, env vars, nix shell)

# غیرفعال‌سازی موقت
direnv deny

# فعال‌سازی مجدد
direnv allow

# نمایش وضعیت فعلی
direnv status
```

**مثال `.envrc`:**
```bash
# در یک پروژه Rust
use nix
# → nix-shell خودکار اجرا می‌شود

# در یک پروژه Python
layout python3
# → virtualenv خودکار ساخته می‌شود
```

**کاربرد:** محیط توسعه izole per-project. وقتی وارد پروژه می‌شوید، ابزارهای مورد نیاز خودکار بارگذاری می‌شوند.

---

## FZF

فایندر فازی. جستجوی فایل، تاریخچه، و هر چیزی با الگوی模糊.

```bash
# جستجوی فایل (از طریق Ctrl-T در شل)
Ctrl-T              # جستجوی فایل و قرار دادن در خط فرمان

# جستجوی دایرکتوری (از طریق Alt-C)
Alt-C               # cd به دایرکتوری انتخاب شده

# پیش‌نمایش فایل
# → fzf با bat پیش‌نمایش نشان می‌دهد

# استفاده در پایپ
ls | fzf            # انتخاب از لیست
git log --oneline | fzf  # انتخاب commit
```

**تنظیمات:** ارتفاع 55%، پیش‌نمایش با bat، تم Catppuccin.

**کاربرد:** انتخاب سریع فایل، دایرکتوری، commit، و هر لیستی.

---

## Carapace

موتور completion برای ۶۰۰+ دستور. completions اضافی برای fish.

```bash
# خودکار فعال — وقتی دستور تایپ می‌کنید:
git ch<Tab>         # → checkout, cherry-pick, ...
docker ru<Tab>      # → run, ...
kubectl ge<Tab>     # → get, ...
```

**کاربرد:** completion‌های بهتر و بیشتر برای دستورات مختلف.

---

## Atuin

تاریخچه شل هوشمند. ذخیره در SQLite، جستجوی fuzzy، sync بین دستگاه‌ها.

```bash
# جستجوی تاریخچه (Ctrl-R)
Ctrl-R              # جستجوی fuzzy در تاریخچه

# نمایش آمار
atuin stats

# sync بین دستگاه‌ها (اختیاری)
atuin register
atuin login
atuin sync
```

**تنظیمات:** style compact، ارتفاع 25، preview فعال، Up arrow غیرفعال (برای حفظ رفتار عادی fish).

**کاربرد:** جستجوی سریع در تاریخچه شل با امکان sync بین دستگاه‌ها.
