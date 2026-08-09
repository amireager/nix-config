# ۰۱ — نمای کلی: هر بخش چیست و چه کار می‌کند

این صفحه نقشه است. می‌گوید هر پوشه چه مسئولیتی دارد و چرا آنجاست، تا وقتی
دنبال چیزی می‌گردی بدانی کجا را باز کنی.

---

## جریان ساخت

وقتی `sw` می‌زنی، این اتفاق می‌افتد:

```
flake.nix
   │
   │  lib.mkHost { hostname = "nixos"; users.amir = ./users/amir; }
   ▼
hosts/nixos/          سخت افزار، بوت لودر و درایورها
   +
modules/nixos/        لایه ی سیستم — کرنل، شبکه، امنیت
   +
home-manager
   └── users/amir/    → modules/home/   لایه ی کاربر
```

و جدا از این، `shells/` که فقط لحظه‌ی `dev <name>` ساخته می‌شود.

نکته‌ی کلیدی: **home-manager یک ماژول NixOS است**، نه یک ابزار جدا. برای همین
`sw` هم سیستم و هم پوشه‌ی خانه را با هم می‌سازد و دستور `hms` جدایی وجود
ندارد.

---

## مشخصات سخت‌افزار میزبان

* **دستگاه:** لپ‌تاپ Acer Aspire A715-42G
* **پردازنده:** AMD Ryzen 5 5500U (معماری Lucienne / Zen 2)
* **گرافیک:** پردازنده گرافیکی مجتمع AMD Radeon + کارت گرافیک Nvidia GTX 1650 Mobile (معماری Turing TU117)
* **کرنل:** `pkgs.linuxPackages_zen` (کم‌تأخیر و بهینه‌شده برای دسکتاپ)
* **درایور گرافیک:** `hardware.nvidia.open = false;` (به دلیل ناپایداری ماژول‌های منبع‌باز روی تراشه TU117 لپ‌تاپ)

---

## `flake.nix` — ورودی

هفت input، همه با `follows = "nixpkgs"` تا فقط یک نسخه‌ی nixpkgs در کل درخت
باشد:

| input | برای چه |
| :--- | :--- |
| `nixpkgs` | شاخه‌ی unstable |
| `home-manager` | لایه‌ی کاربر |
| `niri` | کامپوزیتور گرافیکی |
| `noctalia` | نوار و ویجت‌ها |
| `zen-browser` | مرورگر وب |
| `agenix` | رمزگذاری رازها با age |
| `nix-index-database` | ایندکس از پیش ساخته |

`nix-index-database` یک تصمیم زمانی است: بدون آن، `nix-locate` و `,` تا وقتی
یک ایندکس محلی نسازی (حدود ده دقیقه CPU) کار نمی‌کنند.

---

## `lib/` — دو سازنده

اینجا کوچک است ولی شکل کل درخت را تعیین می‌کند.

**`mkHost`** — ورودی می‌گیرد `{ hostname, hostModules, users }` و یک سیستم
کامل بیرون می‌دهد. ماشین دوم یعنی یک ورودی دیگر در `nixosConfigurations`، نه
کپی کردن درخت.

**`mkDevShell`** — *داده* می‌گیرد (نام، آیکن، توضیح، پکیج‌ها، `tips`) و شل
می‌سازد به‌همراه بنر، متغیرهای محیطی و ثبت GC root در `~/.local/share/dev-roots/`.

قبل از این سازنده، هر شل همان سه کار را دستی تکرار می‌کرد — حدود ۳۰٪ هر فایل،
یازده بار. حالا هر شل فقط داده است.

---

## `hosts/` — یک ماشین

```
hosts/nixos/
├── default.nix     ماژول های سیستم را import می کند + بوت لودر
└── hardware.nix    خروجی nixos-generate-config
```

`hardware.nix` تنها فایلی است که موقع نصب روی ماشین دیگر **باید** عوض شود.

---

## `users/` — یک کاربر

```
users/amir/
├── default.nix     تعریف کاربر در سطح سیستم (گروه ها، شل)
└── home.nix        فهرست ماژول های home که این کاربر می خواهد
```

جدایی عمدی است: `default.nix` چیزی است که NixOS باید بداند، `home.nix` چیزی
است که home-manager می‌سازد.

---

## `modules/nixos/` — لایه‌ی سیستم

| فایل | چه کار می‌کند |
| :--- | :--- |
| `core.nix` | تنظیمات Nix، بوت، کرنل Zen، ZRAM، داکر/پادمن، `nh`، فونت‌های Vazirmatn و JetBrainsMono |
| `network.nix` | NetworkManager، BBR، DNS رمزگذاری‌شده، proxychains |
| `security.nix` | فایروال، sudo-rs، AppArmor، firejail، OpenSnitch، USBGuard |
| `desktop.nix` | niri، greeter، thunar |
| `keyd.nix` | تغییر نگاشت کلید در سطح evdev (تبدیل CapsLock به Esc/Control) |
| `hardware/nvidia.nix` | گرافیک هیبریدی Prime با `open = false` |
| `hardware/laptop.nix` | برق و حرارت لپ‌تاپ |

شرحش در [۰۹ باید و نباید](09-rules.md) — چون بیشترشان تصمیم‌اند نه تنظیم.

---

## `modules/home/` — لایه‌ی کاربر

چهار گروه:

**`cli/`** — `fish.nix` بزرگ‌ترین فایل این گروه است: پرامپت starship، مخفف‌ها،
و توابع خودنوشته مثل `nix_proxy` و `extract`. کنارش `git.nix`، `tmux.nix`،
`zellij.nix` و `tools.nix` (ابزارهای دائمی خط فرمان).
→ [۰۴ خط فرمان](04-cli.md)

**`dev/`** — `nvim/` با ۳۷ پلاگین و ۱۶ فایل lua، `dev-launcher.nix` که دستور
`dev` و تکمیل خودکارش را می‌سازد، و `nix-tools.nix` برای ابزارهای Nix که باید
بیرون از پروژه هم باشند.
→ [۰۳ محیط‌های توسعه](03-dev.md) · [۰۶ ادیتور](06-editor.md)

**`gui/`** — `niri/` (کانفیگ KDL)، `terminal.nix`، `wayland.nix`، `xdg.nix`،
`media.nix`، `browser.nix`.
→ [۰۵ دسکتاپ](05-desktop.md)

**`theme/`** — `gtk.nix` و `noctalia.nix`.
→ [۰۵ دسکتاپ](05-desktop.md)

---

## `shells/` — یازده محیط

هیچ‌کدام نصب نیستند. `dev <name>` می‌سازدشان.

| شل | برای چه |
| :--- | :--- |
| `agent` | عامل‌های هوش مصنوعی (Hermes, OpenCode)، ابزارهای AST (`ast-grep`, `sd`, `difftastic`)، `biome`, `ruff` و اتصال مستقیم به `9router` |
| `python` | پایتون ۳ خالص، `uv`, `pip`, `ruff`, `pyright`, `ipython` با `unset PYTHONPATH` |
| `rust` | Cargo، Rust-Analyzer، Clippy، Watch، Edit، LLDB |
| `go` | Go، Gopls، GolangCI-Lint، Air Live-Reload، Delve |
| `web` | Node.js، Bun، pnpm، TypeScript، Biome، Tailwind |
| `build` | GCC، Clang، CMake، Ninja — با نام `dev c` هم |
| `cli` | ابزارهای تحلیل و پروفایلینگ سنگین (`hyperfine`, `watchexec`, `tokei`, `bandwhich`) |
| `media` | ffmpeg-full، vips، ImageMagick، OCR (`ocrmypdf`), PDF |
| `nix` | بسته‌بندی، بازبینی، تحلیل closure (`nix-check`, `nix-size`) |
| `box` | سندباکس اجرای ابزارها با Home-Swap، مسیر `/work` و رم موقت (-e) |
| `audit` | بررسی CVE، سکرت‌ها، قفل‌فایل‌ها، سخت‌سازی سیستم (`audit-all`) |

`shells/default.nix` رجیستری است و `devShellsMeta` را بیرون می‌دهد — منبعی که
منوی `dev` و تکمیل خودکار هر سه شل از آن می‌خوانند.

---

## `secrets/` — agenix

رازها با `age` رمز شده‌اند و در گیت هستند. کلید خصوصی روی ماشین است، نه در
مخزن. هیچ رمزی به‌صورت متن ساده در این درخت نیست.

---

## کجا دنبال چه بگردی

| دنبال چه هستی | کجا |
| :--- | :--- |
| یک کلید دسکتاپ | `modules/home/gui/niri/config.kdl` |
| یک کلید ادیتور | `modules/home/dev/nvim/lua/*.lua` |
| یک مخفف شل | `modules/home/cli/fish.nix` |
| ابزاری که همیشه باشد | `modules/home/cli/tools.nix` |
| ابزاری فقط در یک زبان | `shells/<زبان>/default.nix` |
| سندباکس و جداسازی | `shells/box/default.nix` |
| تیونینگ کرنل | `modules/nixos/core.nix` |
| قواعد فایروال | `modules/nixos/security.nix` |
| مدل هوش مصنوعی | `modules/home/dev/nvim/lua/ai.lua` |

---

بعدی: [۰۲ دستورهای Nix](02-nix.md)
