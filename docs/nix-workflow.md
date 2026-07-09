# 🧊 Nix Workflow — مدیریت سیستم و پکیج‌ها

## nix

مدیر پکیج غیرقابل‌تغییر (immutable). پایه تمام ابزارهای NixOS.

```bash
# جستجوی پکیج
nix search nixpkgs firefox

# اجرای موقت یک پکیج بدون نصب
nix shell nixpkgs#cowsay
nix run nixpkgs#cowsay -- hello

# ورود به محیط توسعه
nix develop

# نمایش اطلاعات یک flake
nix flake show github:user/repo

# آپدیت inputs
nix flake update
```

**کاربرد:** مدیریت پکیج‌ها، محیط‌های توسعه izole، و ساخت سیستم.

---

## nh (Nix Helper)

جایگزین مدرن `nixos-rebuild` و `home-manager`. خروجی زیباتر، سریع‌تر، و با `nom` ادغام شده.

```bash
# سوییچ سیستم (build + apply)
nh os switch

# تست سیستم (بدون سوییچ — برگشت‌پذیر)
nh os test

# فقط build (بدون apply)
nh os build

# سوییچ home-manager
nh home switch

# فقط build home
nh home build

# پاک‌سازی نسل‌های قدیمی
nh clean all
```

**تنظیمات:** `programs.nh.flake` مسیر فلک را مشخص می‌کند. پاک‌سازی خودکار با `nh clean` فعال است.

**کاربرد:** دستور اصلی برای اعمال تغییرات سیستم. هر بار که فایل‌های nix را ویرایش می‌کنید، `nh os switch` بزنید.

---

## nix-output-monitor (nom)

نمایش زیبای پروسس build. به صورت خودکار توسط `nh` استفاده می‌شود.

```bash
# استفاده مستقیم (معمولاً نیاز نیست — nh خودش استفاده می‌کند)
nom build .#nixosConfigurations.nixos.config.system.build.toplevel
```

**کاربرد:** نمایش درخت وابستگی‌ها و پیشرفت build به صورت بصری.

---

## nvd (Nix Version Diff)

مقایسه دو نسل NixOS. نشان می‌دهد چه پکیج‌هایی اضافه/حذف/آپدیت شده‌اند.

```bash
# مقایسه نسل فعلی با build جدید
nvd diff /run/current-system ./result

# مقایسه دو نسل خاص
nvd diff /nix/var/nix/profiles/system-1-link /nix/var/nix/profiles/system-2-link
```

**کاربرد:** قبل از `switch`، بررسی کنید چه تغییراتی اعمال خواهد شد.

---

## nix-tree

نمایش درخت وابستگی‌های یک derivation در ترمینال.

```bash
# نمایش وابستگی‌های یک پکیج
nix-tree nixpkgs#firefox

# نمایش وابستگی‌های سیستم فعلی
nix-tree /run/current-system
```

**کاربرد:** فهمیدن اینکه یک پکیج چه چیزهایی را نصب می‌کند.

---

## nix-search-tv

جستجوی پکیج‌ها در nixpkgs با رابط TUI (مثل fzf برای nix).

```bash
# جستجوی پکیج
nix-search-tv firefox
nix-search-tv "text editor"
```

**کاربرد:** پیدا کردن نام دقیق پکیج‌ها قبل از نصب.

---

## comma (,)

اجرای هر دستوری بدون نصب. خودکار پکیج مورد نیاز را پیدا و اجرا می‌کند.

```bash
# اجرای دستور بدون نصب
, cowsay hello
, speedtest
, pdftotext --help

# اگر پکیج پیدا نشود، خطا می‌دهد
, nonexistent-command
```

**نیاز به:** `nix-index` (ایندکس پکیج‌ها)

**کاربرد:** وقتی می‌خواهید یک ابزار را یکبار امتحان کنید بدون اینکه permanently نصب شود.

---

## nix-index

ایندکس تمام پکیج‌های nixpkgs. برای `comma` لازم است.

```bash
# ساخت/آپدیت ایندکس (معمولاً cron می‌شود)
nix-index

# جستجوی فایل در پکیج‌ها (مثل apt-file)
nix-locate libstdc++.so
```

**کاربرد:** پیدا کردن اینکه کدام پکیج یک فایل خاص را ارائه می‌دهد.

---

## alejandra

فرمتتر کد Nix. جایگزین `nixpkgs-fmt`.

```bash
# فرمت یک فایل
alejandra flake.nix

# فرمت تمام فایل‌ها در دایرکتوری
alejandra .

# فقط بررسی (بدون تغییر)
alejandra --check .
```

**کاربرد:** فرمت‌بندی خودکار کدهای Nix. در `flake.nix` به عنوان `formatter` تنظیم شده.

---

## statix

لینتر Nix. anti-patterns و مشکلات رایج را پیدا می‌کند.

```bash
# بررسی یک فایل
statix check flake.nix

# بررسی تمام فایل‌ها
statix check .

# فقط نمایش مشکلات (بدون رفع)
statix check --format terse
```

**کاربرد:** بهبود کیفیت کد Nix و پیدا کردن مشکلات قبل از build.

---

## deadnix

پیدا کردن کدهای استفاده‌نشده در فایل‌های Nix.

```bash
# نمایش کدهای استفاده‌نشده
deadnix .

# حذف خودکار کدهای استفاده‌نشده
deadnix --edit .
```

**کاربرد:** تمیز کردن فایل‌های Nix از کدهای اضافی.
