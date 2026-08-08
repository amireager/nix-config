# ۰۳ — محیط‌های توسعه

هیچ کامپایلری، هیچ زبان‌سرور سنگینی، هیچ ابزار پروفایلینگی در سیستم نصب
نیست. یازده محیط وجود دارند که **لحظه‌ی ورود** ساخته می‌شوند.

دلیلش فقط حجم نیست. یک پروفایل سیستم که همه‌چیز در آن است، هر بار
`nix flake update` می‌زنی همه‌چیز را دوباره می‌سازد.

---

## `dev` — چهار حالت استفاده

```sh
dev                    منوی همه ی محیط ها
dev python             ورود
dev python pytest      یک دستور اجرا کن، بعد بیرون بیا
dev -w rust            ببین داخلش چیست، بدون ورود
```

`dev c` همان `dev build` است.

### `dev -w` — نگاه کردن بدون ورود

سؤال «آیا `hyperfine` در `dev cli` هست یا باید نصبش کنم؟» را بدون ساختن کل
محیط جواب می‌دهد.

نکته‌ی فنی: این دستور `nativeBuildInputs` را می‌خواند نه `buildInputs` —
چون `mkShell` هرچه در `packages` بگذاری آنجا می‌گذارد. (این یک باگ بود که
اول `buildInputs` می‌خواند و همیشه خالی برمی‌گشت.)

---

## GC root — چرا محیط‌هایت پاک نمی‌شوند

هر بار وارد یک شل شوی، یک ریشه در `~/.local/share/dev-roots/` ثبت می‌شود.
یعنی `nix store gc` محیطی را که استفاده می‌کنی پاک نمی‌کند.

بدون این، هر پاکسازی یعنی دفعه‌ی بعد نیم ساعت دانلود دوباره — که پشت یک
اتصال فیلترشده اصلاً شوخی نیست.

**ثبت ریشه بعد از خروج از شل انجام می‌شود، نه هم‌زمان.** این یک باگ حل‌شده
است: اجرای `nix print-dev-env` در پس‌زمینه هم‌زمان با `nix develop` باعث
می‌شد هر دو در یک eval cache بنویسند و این خطا روی **هر** فراخوانی `dev`
چاپ شود:

```
error (ignored): SQLite database '…/eval-cache-v6/….sqlite' is busy
```

بی‌ضرر بود ولی زشت. با ترتیبی کردن، تداخل رفت — و چون تا آن لحظه ارزیابی
cache شده، ثبت ریشه تقریباً آنی است.

برای آزاد کردن فضا باید ریشه‌ها را دستی حذف کنی:

```sh
ls ~/.local/share/dev-roots/
rm ~/.local/share/dev-roots/media-profile
nix store gc
```

---

## تکمیل خودکار

`dev <TAB>` در fish، bash و zsh کار می‌کند و نام شل‌ها را با توضیحشان نشان
می‌دهد.

از `nix eval` نمی‌خواند — مستقیم پوشه‌ی `shells/*/` را می‌بیند. **۴۳
میلی‌ثانیه** اندازه‌گیری شده. اگر از `nix eval` می‌خواند، هر بار زدن TAB یک
ارزیابی flake بود.

---

## `mkDevShell` — چرا یک سازنده لازم شد

قبلش هر شل سه چیز یکسان را دستی می‌نوشت: نام، بنر با کد ANSI خام، و
`export DEVSHELL_ACTIVE`. حدود **۳۰٪ هر فایل**، یازده بار تکرار — و جعبه‌ی
بنر باید هر بار که یک خط متن عوض می‌شد دستی تراز می‌شد.

حالا هر شل فقط **داده** است:

```nix
mkDevShell {
  name        = "rust";
  icon        = "🦀";
  description = "Cargo, Rust-Analyzer, Clippy";
  packages    = with pkgs; [ cargo rustc ];
  env.RUST_BACKTRACE = "1";
  tips = [
    { key = "Check & Lint"; cmd = "cargo clippy"; }
  ];
}
```

بنر، تراز کردن ستون‌ها، و متغیرهای محیطی خودکار تولید می‌شوند.

**راه فرار:** هیچ اجباری به استفاده از این سازنده نیست. یک شل می‌تواند
`pkgs.mkShell` خام باشد؛ رجیستری اهمیتی نمی‌دهد.

### اضافه کردن شل جدید

```sh
cp -r shells/_template shells/myenv
# ویرایشش کن، بعد یک خط به shellDirs در shells/default.nix اضافه کن
```

همین. منو، تکمیل خودکار و `dev -w` همه خودکار می‌بینندش — چون همه از
`devShellsMeta` می‌خوانند. **فهرست دومی برای به‌روز کردن وجود ندارد.**

---

## یازده محیط

### `dev nix` — کار روی خود Nix

```sh
nix-init / nurl <url>        اسکلت derivation از یک URL
nix-update <attr>            نسخه و hash را به‌روز کن
nixpkgs-review pr <number>   یک PR را محلی بساز و تست کن
nix-check                    statix + deadnix + flake check
nix-size [path]              حجم closure + ۲۵ عامل بزرگ
```

`nix-check` و `nix-size` خودنوشته‌اند. شرحشان در
[۰۲ دستورهای Nix](02-nix.md).

### `dev python`

```sh
ipython
ruff check . / ruff format .
uv venv / uv pip install -r req.txt
poetry run / poetry add
```

### `dev rust`

```sh
cargo check / cargo clippy
cargo build / cargo run
cargo fmt
```

`rust-analyzer` اینجاست نه در سیستم. وقتی وارد پروژه‌ای با `.envrc` شوی،
`direnv-vim` خودش به Neovim وصلش می‌کند.

### `dev go`

```sh
go run . / go build
golangci-lint run
go test ./...
```

`gopls` و `delve` اینجا هستند. `delve` سی مگابایت است — دلیل خوبی برای
اینکه دائمی نباشد.

### `dev web`

```sh
pnpm install / bun install
pnpm dev / bun run dev
tsc --noEmit
biome check --write .
eslint . / prettier -w .
```

### `dev python` (همراه با ابزارهای داده)

```sh
ipython / marimo edit notebook.py
duckdb / jupyter lab
ruff check . / ruff format .
uv venv / uv pip install -r req.txt
```

### `dev media`

```sh
magick in.png out.webp
vips copy in.jpg out.webp
oxipng -o4 *.png / jpegoptim *.jpg
mediainfo file.mkv
ocrmypdf in.pdf out.pdf
```

`ffmpeg-full` و `vips` سنگین‌اند و به‌ندرت لازم — دقیقاً همان چیزی که نباید
دائمی باشد.

### `dev build` (یا `dev c`)

```sh
cmake -B build && cmake --build build
make
```

`gdb` و `lldb` اینجا هستند. `lldb` وابستگی `libclang` دارد که **۸۴۹ مگابایت**
می‌آورد.

### `dev cli` — ابزارهای تحلیل سنگین

فهرست کاملش در [۰۴ خط فرمان](04-cli.md) است، چون آنجا کنار بقیه‌ی ابزارهای
خط فرمان معنا دارد.

```sh
hyperfine / bandwhich / procs
fx / dasel / jless / jc
ast-grep / tokei / difft
```

### `dev box` و `dev audit`

خودنوشته‌اند و فصل خودشان را دارند →
[۰۸ سندباکس](08-sandbox.md)

---

## چرا زبان‌سرورها در شل‌اند نه در سیستم

`rust-analyzer` و `gopls` در پروفایل سیستم نیستند، ولی ادیتور طوری رفتار
می‌کند که انگار هستند.

مکانیزمش `direnv-vim` است: وارد پروژه‌ای که `.envrc` دارد می‌شوی، محیط فعال
می‌شود، و Neovim زبان‌سرور را از همان محیط برمی‌دارد.

```sh
cd ~/proj/myapp
echo "use flake /etc/nixos#rust" > .envrc
direnv allow
nvim src/main.rs        # rust-analyzer وصل است
```

بیرون از پروژه، هیچ‌کدام در PATH نیستند. نتیجه: پروفایل کوچک، بوت سریع، بدون
از دست دادن قابلیت.

---

بعدی: [۰۴ خط فرمان](04-cli.md)
