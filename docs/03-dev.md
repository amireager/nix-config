# ۰۳ — محیط‌های توسعه: On-Demand و ایزوله

هیچ کامپایلری، هیچ زبان‌سرور سنگینی، هیچ ابزار پروفایلینگی در سیستم پایه نصب
نیست. یازده محیط وجود دارند که **لحظه‌ی ورود** ساخته می‌شوند.

دلیلش فقط حجم نیست. یک پروفایل سیستم که همه‌چیز در آن است، هر بار
`nix flake update` می‌زنی همه‌چیز را دوباره می‌سازد.

---

## `dev` — سریع، On-Demand و قابل مدیریت

```sh
dev                         منوی سریع؛ بدون Flake evaluation
dev -i                      انتخاب تعاملی محیط با FZF
dev python                  ورود تعاملی به شل
dev --shell bash python     ورود با Bash به‌جای Fish
dev python pytest           اجرای مستقیم command با حفظ آرگومان‌ها
dev --dry-run python pytest نمایش Plan بدون evaluation یا اجرا
dev -w rust                 نمایش بسته‌ها با evaluation صریح
dev --keep rust             ساخت یا refresh کردن GC-root بدون ورود
dev --no-keep rust cargo test  اجرا بدون تغییر GC-root
dev --roots                 نمایش rootهای سالم، شکسته، قدیمی و orphan
dev --prune                 پاک‌سازی rootهای شکسته، قدیمی و orphan
dev --unkeep rust           حذف حفاظت GC یک محیط
```

`dev c` همان `dev build` و `dev data` همان `dev python` است. `dev ai` یک محیط مستقل برای اجرای مدل‌های محلی است. `-v` یا `--verbose` جزئیات عملیات Nix و ثبت root را نشان می‌دهد؛ `DEV_SHELL` نیز shell تعاملی پیش‌فرض را انتخاب می‌کند.

### `dev -w` — نگاه کردن بدون ورود

سؤال «آیا `hyperfine` در `dev cli` هست یا باید نصبش کنم؟» را بدون ساختن کل
محیط جواب می‌دهد.

نکته‌ی فنی: این دستور هر دو فهرست `nativeBuildInputs` و `buildInputs` را می‌خواند و نام‌های تکراری را حذف می‌کند. `mkShell` معمولاً ابزارهای قرارگرفته در `packages` را در فهرست اول می‌گذارد؛ نادیده گرفتن آن باعث می‌شد خروجی تقریباً خالی باشد.

### ثبت و مدیریت ریشه GC

هر محیط یک پوشه‌ی ثابت و نام‌دار دارد:

```text
~/.local/share/dev-roots/<name>/
├── profile       → profile-N-link
├── profile-N-link → /nix/store/…-build-env
├── gc-root       → /nix/store/…-build-env
└── last-used
```

`nix develop --profile` همان محیطی را که اجرا می‌شود در `profile` ثبت می‌کند. پیش از اجرای command، helper داخلی `dev` مسیر جاری profile را با `nix-store --add-root --indirect` به‌عنوان GC-root واقعی ثبت می‌کند و سپس history غیرجاری profile را پاک می‌کند. بنابراین برای هر shell فقط current generation و یک لینک ثابت `gc-root` می‌ماند؛ تغییر shell همان root را به closure جدید منتقل می‌کند و لینک‌ها انباشته نمی‌شوند.

این root از build environment و تمام store pathهای referenced در closure آن محافظت می‌کند. در نتیجه تا وقتی `gc-root` سالم و در `dev --roots` با وضعیت `kept` دیده می‌شود، اجرای `nh clean` یا `nix-collect-garbage` نباید پکیج‌های آن محیط را حذف کند. generationهای قبلی که دیگر current نیستند عمداً آزاد می‌شوند.

```sh
dev --keep <name>       ایجاد یا refresh کردن root بدون ورود
dev --no-keep <name>    اجرا بدون ایجاد یا refresh کردن root
dev --roots             بررسی registration، generation و زمان آخرین استفاده
dev --unkeep <name>     حذف root مشخص، حتی اگر shell از registry حذف شده باشد
dev --unkeep-all        حذف همه‌ی rootها با تأیید کاربر
dev --prune             حذف rootهای broken، legacy، unregistered و orphan با تأیید
```

`--no-keep` یک root موجود را حذف نمی‌کند؛ فقط آن را refresh نمی‌کند. برای آزاد کردن واقعی closure باید `--unkeep` اجرا شود. وضعیت‌های منو و `--roots` نیز دقیق‌اند: `kept`، `not kept`، `broken`، `legacy`، `unregistered` و `orphan`. ثبت daemon را می‌توان مستقل نیز دید:

```sh
nix-store --gc --print-roots | grep dev-roots
```

---

## تشریح ۱۱ محیط توسعه و ابزارهای آن‌ها

### ۱. `dev agent` — عامل‌های هوش مصنوعی و خودکارسازی
محیط عملیاتی برای اجرای عامل‌های خودکار (مانند Hermes و OpenCode) با ابزارهای AST:
* **رانتایم‌ها:** `python3`, `uv`, `nodejs_24`, `bun`
* **ابزارهای AI و درگاه:** `aichat` (چت و پایپ خط فرمان)، متغیر `OPENAI_API_BASE=http://127.0.0.1:20128/v1`
* **موتورهای AST و بازنویسی کد:** `ast-grep` (جستجو و ریفکتور ساختاری)، `sd` (جایگزین سریع sed)، `difftastic` (مقایسه ساختاری)، `tokei` (شمارنده خطوط کد)
* **لینتر و فرمتر زیر ۱۰ میلی‌ثانیه:** `ruff` (پایتون)، `biome` (کدهای JS/TS/JSON/CSS)، `shellcheck` و `shfmt` (شل)، `taplo` (فایل‌های TOML)
* **استخراج وب:** `htmlq` (استخراج متن و سلکتورهای CSS از صفحات وب)، `xh`, `curl`

---

### ۲. `dev ai` — آزمایشگاه اجرای محلی مدل‌ها
محیط کامل ولی On-Demand برای مدل‌های کم‌حجم روی GTX 1650 با ۴ گیگابایت VRAM:
* **متن و API:** `ollama-cuda`, `llama-cpp-vulkan`, `aichat`
* **مدیریت مدل:** `huggingface-hub` (`hf`), `git-lfs`, `aria2`
* **رابط‌ها:** `oterm`, `open-webui`
* **صوت:** `whisper-cpp-vulkan`, `piper-tts`, `ffmpeg`
* **تصویر:** `stable-diffusion-cpp-vulkan` (`sd`)
* **RAG و داده:** `qdrant`, `sqlite`, `jq`
* **پایش GPU:** `nvtop`, `nvitop`, `vulkaninfo`
* **ابزارهای محلی:** `ai-doctor` و `ai-storage`

ورود به این shell هیچ سرویس یا مدلی را خودکار اجرا یا دانلود نمی‌کند.

---

### ۳. `dev python` (`dev data`) — پایتون سبک، خالص و ایزوله
* **ابزارها:** `python3`, `uv` (مدیر پکیج و رانر محیط مجازی با Rust)، `pip`, `virtualenv`, `ipython`, `ruff`, `pyright`, `jq`
* **ایزولاسیون:** هوک ورود با دستور `unset PYTHONPATH` از آلوده شدن venv توسط پکیج‌های سراسری Nix جلوگیری می‌کند. فعال‌سازی خودکار `.venv` در صورت وجود.

---

### ۴. `dev rust` — محیط جامع Rust
* **ابزارها:** `cargo`, `rustc`, `rust-analyzer`, `clippy`, `rustfmt`
* **بهره‌وری:** `cargo-watch` (بیلد و اجرای تست حین ذخیره فایل)، `cargo-edit` (`cargo add` / `cargo rm`)
* **دیباگر:** `lldb` (به همراه Pretty-Printers برای وکتورها و رشته‌ها در Neovim DAP)

---

### ۵. `dev go` — محیط توسعه Go
* **ابزارها:** `go`, `gopls`, `golangci-lint`
* **لایو ریلود:** `air` (اجرای مجدد وب‌سرورهای Go حین تغییر سورس)، `delve` (دیباگر dlv)

---

### ۶. `dev web` — توسعه فرانت‌اند و وب مدرن
* **رانتایم‌ها:** `nodejs_24`, `bun`, `pnpm`, `yarn`
* **سرعت و اعتبارسنجی:** `biome` (لینتر و فرمتر ۲۵ برابر سریع‌تر)، `typescript`, `vtsls`, `tailwindcss-language-server`, `prettier`

---

### ۷. `dev build` (`dev c`) — کامپایلرهای C و C++
* **ابزارها:** `gcc`, `clang`, `cmake`, `gnumake`, `ninja`, `pkg-config`, `openssl`, `zlib`
* **دیباگرها:** `lldb` (آداپتور `lldb-dap` برای Neovim) و `gdb`

---

### ۸. `dev cli` — پروفایلینگ و تحلیل عمیق
* **ابزارها:** `hyperfine` (ابزار بنچمارک دقیق)، `watchexec` (اجرای دستور هنگام تغییر فایل)، `tokei`, `hexyl` (هگز ادیتور)، `dasel` (کوئری JSON/YAML/TOML/XML)، `bandwhich` (پایش مصرف پهنای باند هر پروسس)، `procs`, `superfile`

---

### ۹. `dev media` — پردازش تصویر و ویدیو
* **تصویر و ویدیو:** `ffmpeg-full` (با همه کدک‌ها)، `vips` (پردازش تصویر سریع)، `imagemagick`, `oxipng`, `jpegoptim`
* **اسناد و OCR:** `ocrmypdf`, `tesseract`, `pdfarranger`, `qpdf`

---

### ۱۰. `dev nix` — پکیجینگ و بررسی بسته‌ها
* **ابزارها:** `nurl`, `nix-init`, `nix-update`, `nixpkgs-review`, `nix-search-tv`, `nix-check`, `nix-size`

---

### ۱۱. `dev audit` — ممیزی و امنیت
* **ابزارها:** `vulnix`, `gitleaks`, `osv-scanner`, `grype`, `syft`, `trivy`, `lynis`, `audit-all`
