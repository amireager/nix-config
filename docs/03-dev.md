# ۰۳ — محیط‌های توسعه: On-Demand، قابل نگه‌داری و قابل ترکیب

ابزارهای سنگین پروژه‌ای در سیستم پایه انباشته نشده‌اند. دوازده devShell وجود دارد که فقط هنگام درخواست evaluate/realise می‌شوند. این طراحی سه هدف دارد:

1. closure روزمره‌ی سیستم کوچک‌تر و update آن مستقل از toolchainهای نادر باشد؛
2. هر پروژه environment مشخص و قابل تکرار داشته باشد؛
3. ابزار سنگین بعد از اولین استفاده با GC-root واقعی حفظ شود، نه با امید به cache.

ابزارهای روزمره‌ای که کاربر دائماً استفاده می‌کند همچنان global هستند. DevShell جای package manager همه‌چیز نیست.

---

# `dev` — رابط اصلی محیط‌ها

## منو و انتخاب

```bash
dev                         # منوی سریع؛ بدون Flake evaluation
dev -i                      # انتخاب محیط با FZF
dev --help                  # قرارداد command line
dev --verbose rust          # جزئیات Nix و root registration
```

نام‌ها و aliasها:

```text
c       → build
data    → python
default → nix
```

## ورود تعاملی

```bash
dev python
dev --shell bash python
dev --shell zsh web
DEV_SHELL=current dev rust
```

Fish پیش‌فرض است. `current` نام shell را از `$SHELL` می‌گیرد. فقط Fish، Bash و Zsh به‌عنوان interactive shell پشتیبانی می‌شوند.

## اجرای مستقیم command

```bash
dev python python -m pytest -q
dev rust cargo test --workspace
dev go go test ./...
dev web pnpm test
dev c cmake --build build
```

بعد از نام environment، تمام آرگومان‌ها بدون بازنویسی به command داده می‌شوند. برای استفاده‌ی عادی separator اضافی لازم نیست.

## مشاهده‌ی plan بدون اجرا

```bash
dev --dry-run python python -m pytest -q
dev --dry-run --no-keep net nmap example.com
```

Dry-run مسیر Flake، environment، profile، وضعیت keep و command نهایی را چاپ می‌کند؛ environment را evaluate یا اجرا نمی‌کند.

## دیدن packageها

```bash
dev -w rust
dev --what media
```

این تنها مسیر menu نیست و صریحاً Flake output را evaluate می‌کند تا `nativeBuildInputs` و `buildInputs` مؤثر را بخواند. packageهای تکراری قبل از نمایش حذف می‌شوند.

## مالکیت implementation

| بخش | فایل |
| :--- | :--- |
| Home Manager wiring | `modules/home/dev/dev-launcher.nix` |
| CLI parsing، منو و `nix develop` | `modules/home/dev/dev-launcher/runtime.nix` |
| root registration/list/prune | `modules/home/dev/dev-launcher/roots.nix` |
| Fish/Bash/Zsh completion | `modules/home/dev/dev-launcher/completions.nix` |
| نام، group و alias | `shells/registry.nix` |

این split داخلی است و interface بالا را عوض نمی‌کند. Registry هنگام import روی نام‌ها، module membership، groupهای دقیقاً یک‌بار، alias target و collisionها assertion دارد. Flake فقط `devShells.<system>` استاندارد را export می‌کند؛ metadata هر derivation در `passthru.devShellMeta` باقی می‌ماند و منوی سریع برای اجتناب از evaluation، icon/description را از source می‌خواند.

---

# GC-root و lifecycle محیط

## ساختار هر محیط حفظ‌شده

```text
~/.local/share/dev-roots/<name>/
├── profile
├── profile-N-link → /nix/store/…-build-env
├── gc-root        → /nix/store/…-build-env
└── last-used
```

روند ورود نگه‌داری‌شده:

```text
nix develop --profile
  → profile current generation
  → resolve target into /nix/store
  → nix-store --add-root --indirect
  → wipe old profile history
  → update last-used
  → execute shell/command
```

`profile` به‌تنهایی قرارداد کافی برای GC protection نیست؛ helper داخلی `dev-root-enter` یک indirect root واقعی در registry daemon ثبت می‌کند.

## مدیریت rootها

```bash
dev --keep rust           # realise/refresh بدون ورود
dev --no-keep rust cargo check
dev --roots
dev --unkeep rust
dev --unkeep-all
dev --prune
```

`--no-keep` root قبلی را حذف نمی‌کند؛ فقط آن را refresh نمی‌کند. `--prune` فقط پس از confirmation، directory-onlyها و stateهای broken/legacy/orphan را پاک می‌کند و به `kept` دست نمی‌زند.

## معنی statusها

سه حالت عادی منو مستقیماً از filesystem محلی خوانده می‌شوند:

| علامت | وضعیت | معنی |
| :---: | :--- | :--- |
| `●` | `kept` | `gc-root` یک symlink سالم به `/nix/store` است |
| `◐` | `directory only` | directory محیط ساخته شده ولی `gc-root` ندارد |
| `○` | `not used` | هنوز directory/rootی برای محیط ساخته نشده است |

`◆ legacy` فقط layout قدیمی را نشان می‌دهد، `◆ orphan` directory خارج از Registry است و `! broken` مخصوص symlink خراب یا path غیرمنتظره در محل `gc-root` است.

منوی `dev` و `dev -i` عمداً `nix-store --gc --print-roots` اجرا نمی‌کنند؛ ثبت root هنگام ورود به‌صورت synchronous انجام می‌شود و failure همان‌جا جلوی ورود را می‌گیرد. این کار منو را سریع نگه می‌دارد و وضعیت نمایشی را به format خروجی نسخه‌های مختلف Nix وابسته نمی‌کند. برای audit مستقل daemon همچنان command پایین وجود دارد.

## closure size

`dev --roots` اندازه‌ی closure هر root را جداگانه نشان می‌دهد. این اعداد additive نیستند؛ چند محیط می‌توانند compiler، libc یا runtime یکسان را share کنند.

بررسی مستقل:

```bash
nix-store --gc --print-roots | rg "$HOME/.local/share/dev-roots"
nix path-info -Sh ~/.local/share/dev-roots/rust/gc-root
```

---

# اتصال به پروژه با direnv

برای repositoryای که همیشه یک environment مشخص می‌خواهد:

```bash
printf '%s\n' 'use flake /etc/nixos#rust' > .envrc
direnv allow
```

برای Python:

```bash
printf '%s\n' 'use flake /etc/nixos#python' > .envrc
direnv allow
uv venv
```

`.envrc` باید داخل project review شود؛ `direnv allow` اعتماد صریح به همان revision است. فایل ناشناس را کورکورانه allow نکنید.

Neovim دارای `direnv-vim` است. وقتی editor داخل project environment قرار بگیرد، binaryهایی مثل `rust-analyzer`، `gopls`، `lldb-dap` و `dlv` روی PATH ظاهر می‌شوند و config موجود آن‌ها را استفاده می‌کند.

---

# انتخاب محیط

| نیاز | محیط |
| :--- | :--- |
| agent، AST rewrite، lint چندزبانه | `agent` |
| inference محلی، speech/image/RAG | `ai` |
| Python application یا script | `python` |
| Rust | `rust` |
| Go | `go` |
| Node/TypeScript/frontend | `web` |
| C/C++ یا build dependency عمومی | `build` / `c` |
| profiling، log، structured data، transfer | `cli` |
| proxy core، packet/TLS/throughput | `net` |
| image/video/OCR/PDF processing | `media` |
| Nix packaging و closure analysis | `nix` |
| secret/CVE/SBOM/hardening audit | `audit` |

---

# ۱. `dev agent` — ابزار عملیاتی agentها

این محیط خود agent خاصی را الزام نمی‌کند؛ runtime و ابزارهایی را فراهم می‌کند که Hermes، OpenCode یا scriptهای agent موجود در پروژه نیاز دارند.

## محتوا

- Python، uv، Node.js 24 و Bun
- `aichat` با gateway محلی 9router
- `ast-grep`, `rg`, `fd`, `sd`, `difftastic`, `tokei`
- Ruff، Biome، Pyright، ShellCheck، shfmt و Taplo
- `htmlq`, `jq`, `yq`, `xh`, `curl`
- Hyperfine و Git

Environment:

```text
OPENAI_API_BASE=http://127.0.0.1:20128/v1
OPENAI_API_KEY=local
AI_GATEWAY=http://127.0.0.1:20128
```

کلید واقعی در repository قرار نمی‌گیرد؛ مقدار `local` فقط قرارداد gateway محلی است.

## recipeها

```bash
# تحلیل ساختاری functionهای بدون پارامتر در Rust
dev agent ast-grep --pattern 'fn $NAME() { $$$BODY }' --lang rust

# preview بازنویسی Python
dev agent ruff check .
dev agent ruff format --check .

# QA وب
dev agent biome check .

# استخراج article از HTML
dev agent sh -c "curl -fsSL https://example.com | htmlq article --text"

# ساخت پیام commit از diff؛ قبل از ارسال، داده‌ی حساس را بررسی کنید
git diff --cached | dev agent aichat 'Write a concise conventional commit message'

# مقایسه‌ی benchmark دو command
dev agent hyperfine --warmup 3 'rg pattern .' 'grep -R pattern .'
```

ورود shell اگر `.venv` موجود باشد آن را فعال می‌کند؛ چیزی ایجاد یا دانلود نمی‌کند.

---

# ۲. `dev ai` — inference محلی و GPU

ورود به این environment هیچ service یا model downloadی را شروع نمی‌کند.

## محتوا

- Ollama CUDA و llama.cpp Vulkan
- Hugging Face CLI، Git LFS و aria2
- nvtop، nvitop و vulkaninfo
- Whisper.cpp، Piper و FFmpeg
- OTerm و Open WebUI
- stable-diffusion.cpp Vulkan
- Qdrant، SQLite، jq و curl
- helperهای `ai-doctor` و `ai-storage`

## شروع کنترل‌شده

```bash
dev ai ai-doctor
dev ai ai-storage
dev ai ollama serve
```

در terminal دیگر:

```bash
dev ai ollama list
dev ai curl --fail http://127.0.0.1:11434/api/version
```

llama.cpp با مدل موجود:

```bash
dev ai llama-bench -m /path/to/model.gguf
dev ai llama-server -m /path/to/model.gguf --host 127.0.0.1 --port 8080
```

برای GTX 1650 با ۴ GiB VRAM، مدل‌های 1B–4B با quantization Q4 و context محدود نقطه‌ی شروع منطقی‌اند. مدل در docs پیشنهاد می‌شود ولی خودکار دانلود نمی‌شود.

## Box و GPU

```bash
dev ai box -g -s /path/to/models:/models \
  llama-bench -m /models/model.gguf
```

`-s` مدل را read-only share می‌کند. `box -g` فقط device و driver pathهای لازم را اضافه می‌کند؛ project جاری خودکار mount نمی‌شود.

---

# ۳. `dev python` / `dev data`

محیط پایه عمداً data stack بزرگی ندارد. dependency برنامه در `.venv` همان پروژه نصب می‌شود.

```bash
dev python
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
python -m pytest -q
ruff check .
ruff format --check .
pyright
```

اجرای بدون ورود:

```bash
dev python uv run pytest -q
dev python python -m compileall -q src
```

`PYTHONPATH` هنگام ورود unset می‌شود تا package سراسری Nix داخل virtualenv تزریق نشود. اگر `.venv` وجود داشته باشد، shell آن را خودکار فعال می‌کند.

برای project reproducible، lockfile مربوط به uv/Poetry را commit کنید؛ خود `.venv` را نه.

---

# ۴. `dev rust`

```bash
dev rust cargo check --workspace --all-targets
dev rust cargo test --workspace
dev rust cargo clippy --workspace --all-targets -- -D warnings
dev rust cargo fmt --all -- --check
dev rust cargo watch -x check -x test
```

افزودن dependency:

```bash
dev rust cargo add serde --features derive
dev rust cargo rm unused-crate
```

Debug:

```bash
dev rust lldb target/debug/app
```

Neovim DAP از `lldb-dap` همین environment و pretty-printerهای sysroot Rust استفاده می‌کند.

---

# ۵. `dev go`

```bash
dev go go test ./...
dev go go test -race ./...
dev go golangci-lint run
dev go go vet ./...
dev go air
```

Debug package:

```bash
dev go dlv debug ./cmd/server
dev go dlv test ./internal/package
```

`gopls` و `dlv` global نیستند؛ project environment آن‌ها را به Neovim می‌دهد.

---

# ۶. `dev web`

```bash
dev web node --version
dev web pnpm install --frozen-lockfile
dev web pnpm test
dev web biome check .
dev web biome check --write .
dev web tsc --noEmit
dev web prettier --check .
```

برای repository جدید یک package manager را انتخاب کنید و lockfileهای چند manager را هم‌زمان commit نکنید.

Bun برای script سریع:

```bash
dev web bun run script.ts
dev web bun test
```

وجود ESLint/Prettier برای compatibility است؛ اگر project روی Biome استاندارد شده، pipeline موازی بی‌دلیل نسازید.

---

# ۷. `dev build` / `dev c`

CMake out-of-tree:

```bash
dev c cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
dev c cmake --build build --parallel
dev c ctest --test-dir build --output-on-failure
```

Compile command مستقیم:

```bash
dev c clang -std=c17 -Wall -Wextra -Wpedantic -g main.c -o app
dev c g++ -std=c++23 -Wall -Wextra -Wpedantic -g main.cpp -o app
```

Debug:

```bash
dev c gdb --args ./app arg1
dev c lldb -- ./app arg1
```

`build/` معمولاً generated است و نباید وارد Git شود. در این workspace نیز directoryهایی با نام build به‌عنوان artifact در نظر گرفته می‌شوند.

---

# ۸. `dev cli` — تحلیل و automation سنگین

Benchmark معتبر:

```bash
dev cli hyperfine --warmup 5 --runs 20 \
  'rg --files >/dev/null' \
  'fd -t f . >/dev/null'
```

Structured data:

```bash
dev cli fx data.json
dev cli jless data.json
dev cli dasel -f config.toml '.database.port'
dev cli jc ls -l /etc | jq '.[] | select(.size > 1048576)'
```

Process و log:

```bash
dev cli procs --tree
dev cli tailspin application.log
dev cli bandwhich
```

Background queue:

```bash
dev cli pueue add -- long-command
dev cli pueue status
```

Transfer:

```bash
dev cli wormhole send artifact.tar.zst
dev cli rclone copy --progress ./backup remote:backup
```

ابتدا destination و credential scope را با command read-only مانند `rclone lsd remote:` بررسی کنید.

---

# ۹. `dev net` — network و proxy tooling

این environment package فراهم می‌کند؛ service خودکار بالا نمی‌آورد و DNS سیستم را تغییر نمی‌دهد.

## interface و route

```bash
dev net ip -brief address
dev net ip route show table all
dev net ethtool interface-name
dev net iw dev
```

## port و packet

```bash
dev net nmap -sV --reason -Pn host.example
dev net tcpdump -ni any 'tcp port 443'
dev net termshark -i interface-name
```

برای capture معمولاً capability یا sudo لازم است. فقط شبکه و host مجاز را بررسی کنید.

## TLS و WebSocket

```bash
dev net testssl --warnings batch host.example:443
dev net websocat wss://host.example/socket
dev net oha -n 200 -c 10 https://host.example/health
```

## proxy coreها

`sing-box`, `xray`, `v2rayn`, `tor`, `tun2proxy`, `byedpi` و WireGuard tools فقط binary/config tooling هستند. lifecycle و config آن‌ها عمداً service declarative این repository نیست.

---

# ۱۰. `dev media`

Image:

```bash
dev media magick input.png -strip -resize '1920x1920>' output.webp
dev media vips thumbnail input.jpg output.webp 1280
dev media oxipng -o 4 --strip safe *.png
dev media jpegoptim --strip-all --max=85 *.jpg
```

Video/audio:

```bash
dev media ffmpeg -i input.mkv -map 0 -c copy output.mkv
dev media mediainfo input.mkv
dev media mkvmerge -o output.mkv video.mkv audio.mka
```

قبل از transcode طولانی، stream mapping را با `ffprobe`/`mediainfo` بررسی کنید. `-c copy` remux است و quality را تغییر نمی‌دهد.

PDF/OCR:

```bash
dev media qpdf --check document.pdf
dev media qpdf input.pdf --pages . 1-5 -- output.pdf
dev media ocrmypdf --deskew --rotate-pages input.pdf output.pdf
dev media tesseract scan.png stdout -l eng
```

GUIهای `pinta` و `pdfarranger` نیز در environment موجودند. Player/viewerهای روزمره در Home Manager global هستند.

---

# ۱۱. `dev nix`

```bash
dev nix nix-check
dev nix nix-size /run/current-system
dev nix nix-search-tv
dev nix nurl https://github.com/owner/project
dev nix nix-init https://github.com/owner/project
dev nix nix-prefetch-git https://github.com/owner/project
```

Review PR فقط در checkout مناسب nixpkgs و با آگاهی از build cost:

```bash
dev nix nixpkgs-review pr 123456
```

جزئیات بیشتر: [۰۲ عملیات Nix](02-nix.md).

---

# ۱۲. `dev audit`

Audit ترکیبی:

```bash
dev audit audit-repo .
dev audit audit-system
dev audit audit-all .
```

`audit-repo` working tree و Git history را با Gitleaks بررسی می‌کند و اگر lockfile شناخته‌شده وجود داشته باشد OSV Scanner را اجرا می‌کند.

Supply chain:

```bash
dev audit syft dir:. -o cyclonedx-json > sbom.json
dev audit grype sbom:sbom.json
dev audit trivy config .
dev audit trivy fs .
```

Container:

```bash
dev audit trivy image registry.example/app:tag
dev audit dive registry.example/app:tag
dev audit cosign verify registry.example/app:tag
```

Hardening:

```bash
dev audit lynis audit system
```

Audit read-only طراحی شده است، ولی scanner ممکن است database vulnerability را از شبکه دریافت یا cache کند. نتیجه‌ی scanner حکم قطعی نیست؛ version، exploitability و false positive باید بررسی شوند.

---

# ترکیب devShell و Box

Environment ابزار می‌دهد؛ Box دسترسی process را محدود می‌کند:

```bash
# Agent با Home و work خصوصی
dev agent box --secure python untrusted_agent.py

# تست offline
dev web box --net none pnpm test

# source صریح read-only و output صریح writable
dev media box -s "$PWD/input:/input" -S "$PWD/output:/output" \
  ffmpeg -i /input/video.mkv /output/video.mp4
```

فراخوانی فعلی project به‌صورت خودکار mount نمی‌شود؛ اگر command به source نیاز دارد share باید صریح باشد.

---

# troubleshooting

## Flake پیدا نمی‌شود

```bash
set -gx NIX_CONFIG_FLAKE /path/to/nix-config
dev
```

مسیر استاندارد نصب `/etc/nixos` است. fallbackهای `~/nix-config` و `~/projects/nix-config` برای recovery وجود دارند.

## shell ثبت نشده

فقط ایجاد `shells/name/default.nix` کافی نیست؛ نام باید در `shells/registry.nix` و یک group ثبت شود.

## root شکسته

```bash
dev --roots
dev --prune
dev --keep environment-name
```

قبل از prune خروجی plan و registration state را بخوانید.

## LSP در Neovim پیدا نمی‌شود

```bash
command -v rust-analyzer
command -v gopls
command -v lldb-dap
```

Editor باید از project environment اجرا شود یا direnv آن را وارد PATH کرده باشد.

---

بعدی: [۰۴ خط فرمان](04-cli.md)
