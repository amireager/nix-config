# ۰۳ — محیط‌های توسعه: On-Demand و ایزوله

هیچ کامپایلری، هیچ زبان‌سرور سنگینی، هیچ ابزار پروفایلینگی در سیستم پایه نصب
نیست. یازده محیط وجود دارند که **لحظه‌ی ورود** ساخته می‌شوند.

دلیلش فقط حجم نیست. یک پروفایل سیستم که همه‌چیز در آن است، هر بار
`nix flake update` می‌زنی همه‌چیز را دوباره می‌سازد.

---

## `dev` — چهار حالت استفاده

```sh
dev                    منوی رنگی و زیبای همه ی محیط ها
dev python             ورود تعاملی به شل
dev python pytest      یک دستور اجرا کن، بعد بیرون بیا
dev -w rust            ببین داخلش چیست، بدون ورود
```

`dev c` همان `dev build` است و `dev ai` همان `dev agent`.

### `dev -w` — نگاه کردن بدون ورود

سؤال «آیا `hyperfine` در `dev cli` هست یا باید نصبش کنم؟» را بدون ساختن کل
محیط جواب می‌دهد.

نکته‌ی فنی: این دستور `nativeBuildInputs` را می‌خواند نه `buildInputs` —
چون `mkShell` هرچه در `packages` بگذاری آنجا می‌گذارد. (این یک باگ بود که
اول `buildInputs` می‌خواند و همیشه خالی برمی‌گشت.)

### ثبت ریشه GC (Garbage Collection Protection)

هر بار که وارد یک شل می‌شوی، دستور `dev` یک GC-root در
`~/.local/share/dev-roots/<name>-profile` ثبت می‌کند. یعنی محیطی که نیم ساعت
دانلود شده، با اجرای `nh clean` یا `nix-collect-garbage` پاک نمی‌شود تا زمانی که
خودت صراحتاً آن را حذف کنی.

---

## تشریح ۱۱ محیط توسعه و ابزارهای آن‌ها

### ۱. `dev agent` (`dev ai`) — عامل‌های هوش مصنوعی و خودکارسازی
محیط عملیاتی برای اجرای عامل‌های خودکار (مانند Hermes و OpenCode) با ابزارهای AST:
* **رانتایم‌ها:** `python3`, `uv`, `nodejs_22`, `bun`
* **ابزارهای AI و درگاه:** `aichat` (چت و پایپ خط فرمان)، متغیر `OPENAI_API_BASE=http://127.0.0.1:20128/v1`
* **موتورهای AST و بازنویسی کد:** `ast-grep` (جستجو و ریفکتور ساختاری)، `sd` (جایگزین سریع sed)، `difftastic` (مقایسه ساختاری)، `tokei` (شمارنده خطوط کد)
* **لینتر و فرمتر زیر ۱۰ میلی‌ثانیه:** `ruff` (پایتون)، `biome` (کدهای JS/TS/JSON/CSS)، `shellcheck` و `shfmt` (شل)، `taplo` (فایل‌های TOML)
* **استخراج وب:** `htmlq` (استخراج متن و سلکتورهای CSS از صفحات وب)، `xh`, `curl`

---

### ۲. `dev python` (`dev data`) — پایتون سبک، خالص و ایزوله
* **ابزارها:** `python3`, `uv` (مدیر پکیج و رانر محیط مجازی با Rust)، `pip`, `virtualenv`, `ipython`, `ruff`, `pyright`, `jq`
* **ایزولاسیون:** هوک ورود با دستور `unset PYTHONPATH` از آلوده شدن venv توسط پکیج‌های سراسری Nix جلوگیری می‌کند. فعال‌سازی خودکار `.venv` در صورت وجود.

---

### ۳. `dev rust` — محیط جامع Rust
* **ابزارها:** `cargo`, `rustc`, `rust-analyzer`, `clippy`, `rustfmt`
* **بهره‌وری:** `cargo-watch` (بیلد و اجرای تست حین ذخیره فایل)، `cargo-edit` (`cargo add` / `cargo rm`)
* **دیباگر:** `lldb` (به همراه Pretty-Printers برای وکتورها و رشته‌ها در Neovim DAP)

---

### ۴. `dev go` — محیط توسعه Go
* **ابزارها:** `go`, `gopls`, `golangci-lint`
* **لایو ریلود:** `air` (اجرای مجدد وب‌سرورهای Go حین تغییر سورس)، `delve` (دیباگر dlv)

---

### ۵. `dev web` — توسعه فرانت‌اند و وب مدرن
* **رانتایم‌ها:** `nodejs_22`, `bun`, `pnpm`, `yarn`
* **سرعت و اعتبارسنجی:** `biome` (لینتر و فرمتر ۲۵ برابر سریع‌تر)، `typescript`, `vtsls`, `tailwindcss-language-server`, `prettier`

---

### ۶. `dev build` (`dev c`) — کامپایلرهای C و C++
* **ابزارها:** `gcc`, `clang`, `cmake`, `gnumake`, `ninja`, `pkg-config`, `openssl`, `zlib`
* **دیباگرها:** `lldb` (آداپتور `lldb-dap` برای Neovim) و `gdb`

---

### ۷. `dev cli` — پروفایلینگ و تحلیل عمیق
* **ابزارها:** `hyperfine` (ابزار بنچمارک دقیق)، `watchexec` (اجرای دستور هنگام تغییر فایل)، `tokei`, `hexyl` (هگز ادیتور)، `dasel` (کوئری JSON/YAML/TOML/XML)، `bandwhich` (پایش مصرف پهنای باند هر پروسس)، `procs`, `superfile`

---

### ۸. `dev media` — پردازش تصویر و ویدیو
* **تصویر و ویدیو:** `ffmpeg-full` (با همه کدک‌ها)، `vips` (پردازش تصویر سریع)، `imagemagick`, `oxipng`, `jpegoptim`
* **اسناد و OCR:** `ocrmypdf`, `tesseract`, `pdfarranger`, `qpdf`

---

### ۹. `dev nix` — پکیجینگ و بررسی بسته‌ها
* **ابزارها:** `nurl`, `nix-init`, `nix-update`, `nixpkgs-review`, `nix-search-tv`, `nix-check`, `nix-size`

---

### ۱۰. `dev audit` — ممیزی و امنیت
* **ابزارها:** `vulnix`, `gitleaks`, `osv-scanner`, `grype`, `syft`, `trivy`, `lynis`, `audit-all`

---

### ۱۱. `dev box` — موتور سندباکس Universal
* ابزار خودنوشته اجرای امن با ایزولاسیون Zero-Trust و Home-Swap (تشریح کامل در [۰۸ سندباکس](08-sandbox.md)).
