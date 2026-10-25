# ۱۰ — تصمیم‌های معماری

این فایل Architecture Decision Record پروژه است. بقیه‌ی docs می‌گویند سیستم چه دارد و چطور استفاده می‌شود؛ این فصل توضیح می‌دهد چرا راه فعلی انتخاب شد، چه چیزی امتحان شد و چه trade-offی پذیرفته شد.

یک تصمیم خوب باید این چهار بخش را داشته باشد:

```text
وضعیت/مسئله
گزینه‌های بررسی‌شده
تصمیم و دلیل
پیامدها و شرط بازنگری
```

---

# AI completion حذف شد، بعد از این‌که کار کرد

## مسئله

Completion شبکه‌ای هنگام هر مکث editor درخواست می‌فرستاد. gateway برای یک completion کوچک prompt بزرگی شامل system، few-shot و context provider می‌ساخت.

```text
chat: system + few-shot + gateway context ≈ 2507 token
FIM:  prefix + suffix                         ≈   50 token
```

## گزینه‌ها

1. حفظ chat completion؛
2. استفاده از endpoint مدل FIM؛
3. حذف as-you-type و نگه‌داشتن action صریح.

## یافته

Gateway می‌توانست chat model را پشت endpoint FIM route کند و پاسخ `200` با body خالی برگرداند. نتیجه از error واضح بدتر بود: editor ظاهراً قفل یا خراب به نظر می‌رسید.

## تصمیم

Completion خودکار حذف شد. CodeCompanion فقط با کلید صریح اجرا می‌شود. هیچ network request در startup یا هنگام تایپ وجود ندارد.

## شرط بازنگری

فقط وقتی gateway مدل FIM واقعی، failure قابل مشاهده و latency قابل اندازه‌گیری تضمین کند.

---

# command-not-found باید قبل از زنجیره override می‌شد

## مسئله

غلط تایپی Fish چند ثانیه package database را می‌گشت.

غیرفعال‌کردن integration nix-index و NixOS command-not-found کافی نبود، چون Fish fallback دیگری روی هر binary با نام `command-not-found` در PATH داشت.

## تصمیم

تابع `fish_command_not_found` به‌صورت صریح تعریف شد و با status 127 سریع برمی‌گردد.

اندازه‌گیری روی Fish واقعی:

```text
قبل: 2.017s
بعد: 0.013s
```

`nix-locate` و comma همچنان دستی در دسترس‌اند؛ فقط typo خودکار تبدیل به package search نمی‌شود.

---

# Box از Home-Swap استفاده می‌کند

## مسئله

Agentها و installerها نباید `~/.ssh`، credentialهای ابزارهای دیگر یا Home واقعی را ببینند. استفاده از user مجازی `/home/dev` نیز Python venvهای دارای shebang مطلق را می‌شکست:

```text
#!/home/amir/project/.venv/bin/python
```

## تصمیم

Box یک storage خصوصی `.box/home` را روی همان path واقعی Home داخل namespace bind می‌کند. Path ثابت می‌ماند، ولی محتوا عوض می‌شود.

```text
host:    /home/amir → داده واقعی
sandbox: /home/amir → <project>/.box/home
```

Project جاری نیز خودکار mount نمی‌شود. `/work` از `.box/work`، tmpfs یا `-w` صریح می‌آید.

## پیامد

- shebang و absolute pathها کار می‌کنند؛
- credentialهای Home وجود ندارند؛
- standard mode برای سازگاری PATH/environment را حفظ می‌کند؛
- برای کد واقعاً نامطمئن `--secure` لازم است؛
- Box VM یا مرز امنیتی kernel نیست.

---

# `--secure` و network دو محور مستقل‌اند

Security mode environment و mountهای broad `/run` و `/var` را محدود می‌کند. قطع network تصمیم جداست:

```bash
box --secure command
box --net none command
box --secure --net none command
```

این جداسازی اجازه می‌دهد command با Home مخفی ولی اینترنت فعال اجرا شود، یا تست offline بدون پاک‌کردن تمام environment انجام شود.

---

# Project invocation directory خودکار share نمی‌شود

Auto-mount کردن `$PWD` استفاده را راحت‌تر می‌کرد، ولی isolation را غیرقابل پیش‌بینی می‌کرد: commandی که ظاهراً در sandbox بود کل source فعلی را read/write می‌دید.

تصمیم:

- persistent default: `.box/work`؛
- ephemeral: tmpfs؛
- custom project: فقط `-w`؛
- host data: فقط `-s` read-only یا `-S` read-write.

Auto-map directoryهای `.box/<name>` به `/<name>` حفظ شده، چون خودشان storage خصوصی sandbox هستند نه host share تصادفی.

---

# Python shell عمداً data stack ندارد

## مسئله

Pandas، PyTorch و Jupyter global closure را بسیار بزرگ و project dependency را مبهم می‌کردند. packageهای Nix می‌توانستند virtualenv را با `PYTHONPATH` آلوده کنند.

## تصمیم

`dev python` فقط runtime و tooling پایه دارد: Python، uv/pip/Poetry، IPython، Ruff، Pyright و jq. هر پروژه dependency خود را در `.venv` نصب می‌کند و shell `PYTHONPATH` را unset می‌کند.

## پیامد

Project lockfile منبع dependency است؛ devShell compiler/runtime و ابزار پایه را می‌دهد.

---

# DevShellها on-demand هستند ولی بعد از استفاده ناپدید نمی‌شوند

## مسئله

On-demand بودن بدون root یعنی GC می‌تواند toolchain سنگین را حذف کند و ورود بعدی دوباره download/realise شود. Profile symlink ظاهری نیز لزوماً daemon root ثبت‌شده نیست.

## تصمیم

`dev` برای هر environment:

1. profile ثابت می‌سازد؛
2. target store را resolve می‌کند؛
3. indirect GC-root واقعی ثبت می‌کند؛
4. history قدیمی profile را پاک می‌کند؛
5. last-used را ثبت می‌کند.

Registration هنگام ورود synchronous است و failure همان‌جا shell را متوقف می‌کند. نمایش روزمره فقط سه state محلی `kept`، `directory only` و `not used` را می‌خواند؛ daemon-wide query از مسیر منو حذف شده است چون هم کند بود و هم به format متن خروجی Nix وابستگی شکننده ایجاد می‌کرد. Audit مستقل daemon همچنان با `nix-store --gc --print-roots` ممکن است.

---

# Registry داده‌ی مرکزی است، نه output سفارشی Flake

نام، ترتیب، group و alias محیط‌ها در `shells/registry.nix` هستند. Assertionهای کوچک همان‌جا نام نامعتبر، module/member گمشده، membership تکراری، alias target ناموجود و collision را زود رد می‌کنند.

Metadata هر محیط در `passthru.devShellMeta` derivation باقی می‌ماند، اما Flake فقط `devShells.<system>` استاندارد را export می‌کند. output سفارشی `devShellsMeta` حذف شد چون consumer خارجی نداشت، schema استاندارد نبود و launcher برای منوی evaluation-free باید source را بخواند.

Runtime، root management و completion فایل‌های مستقل‌اند؛ CLI عمداً همان قرارداد قبلی را حفظ می‌کند.

---

# ابزار روزمره global می‌ماند

کوچک‌ترین closure ممکن هدف اصلی نیست. `rg`, `fd`, network diagnosis، transfer toolها و Nix QA که مرتب یا در زمان خرابی استفاده می‌شوند global هستند.

DevShell برای ابزار سنگین، language-specific، audit، media processing و workloadهای نادر است. انتقال ابزار روزمره به `dev net` یا `dev cli` به‌خاطر purity ظاهری رد شد، چون friction روزانه ایجاد می‌کرد.

---

# Nix tooling اضطراری با packaging tooling فرق دارد

Global:

- `statix`, `deadnix`, `alejandra`, `nixd`؛
- `nix-tree`, `nix-diff`, `nix-du`, `nix-melt`؛
- nix-index database و comma.

On-demand در `dev nix`:

- package scaffold/update/prefetch؛
- nixpkgs review؛
- parallel flake build/search؛
- helperهای repository.

قاعده: ابزاری که وقتی config خراب است لازم می‌شود نباید پشت همان config خراب پنهان باشد.

---

# Nix-check عمداً Flake را evaluate نمی‌کند

یک health check اولیه باید سریع، deterministic و بدون network/build باشد. بنابراین `nix-check` فقط parser مستقل فایل‌ها، Statix، Deadnix و Alejandra را اجرا می‌کند.

Flake evaluation و build مرحله‌ی جدا و صریح deployment هستند. Source CI نیز همین مرز را رعایت می‌کند.

---

# هزینه‌ی failure نادر سراسری نمی‌شود

هدف performance این host بیشترین throughput واقعی است، نه بیشترین عدد در هر knob. روی Ryzen 5 5500U، build capacity به سه derivation و چهار thread برای هرکدام محدود می‌شود تا حاصل `max-jobs × cores` از دوازده thread ماشین عبور نکند.

Concurrency، timeout و retry دانلود در default نگه‌داری‌شده‌ی Nix می‌مانند. `fallback=false` مانع source build ناخواسته پس از شکست substitute شناخته‌شده می‌شود، ولی cache miss عادی هنوز می‌تواند build شود. Store به‌جای hash/hardlink هم‌زمان با هر import، هفته‌ای یک‌بار با اولویت idle و فقط روی برق AC بهینه می‌شود.

دانلود حجیم شکست‌خورده نیز hook دائمی ندارد: همان مورد خاص با curl/aria2 به‌صورت دستی resume، با Store path مورد انتظار تطبیق و سپس با command رسمی Nix import می‌شود.

---

# DNS مالک واحد دارد

## مسئله

ترکیب NetworkManager، resolved و resolvconf می‌توانست `/etc/resolv.conf` را بازنویسی یا regular file قدیمی را حفظ کند.

## تصمیم

- NetworkManager DNS را مدیریت نمی‌کند؛
- resolved خاموش است؛
- resolvconf خاموش است؛
- `/etc/resolv.conf` به static Nix file با `127.0.0.1` force می‌شود؛
- DNSCrypt fallback/bootstrap را داخل خود مدیریت می‌کند.

Activation symlink صریح به‌خاطر regular file قدیمی باقی مانده است. این imperative است، ولی owner و دلیل مشخص دارد.

---

# Proxy scopeها یکی نیستند

| ابزار | scope |
| :--- | :--- |
| `proxy_on` | همین shell و childها |
| `px` | یک command از proxychains |
| `box --proxy` | environment داخل sandbox |
| `nix_proxy` / `nix-proxy` | daemon تا off/reboot؛ `test` بدون تغییر service |

یکی‌کردن این‌ها در toggle سراسری رد شد، چون هر scope failure و cleanup متفاوت دارد. Host/port پایه در `lib.proxy` مشترک و authoritative است؛ `px`، proxychains و Box endpoint دیگری را hard-code نمی‌کنند. Lifecycle مشترک نیست.

---

# NVIDIA open module روی این سخت‌افزار رد شد

GTX 1650 Mobile با TU117 و hybrid AMD/NVIDIA روی open kernel module ناپایدار بود. proprietary driver با `hardware.nvidia.open = false` برای suspend/resume و Prime offload قابل اعتمادتر بود.

این تصمیم قابل تعمیم به GPU دیگر نیست. Host جدید باید طبق سخت‌افزار خودش انتخاب کند.

---

# Zen kernel انتخاب workload است

Zen kernel برای latency desktop و responsiveness این لپ‌تاپ انتخاب شده است. این ادعای بهترین kernel برای server یا battery life عمومی نیست.

اگر regression hardware، power یا driver ایجاد شود، بازگشت به kernel استاندارد nixpkgs گزینه‌ی اول diagnosis است.

---

# Noctalia idle در GUI می‌ماند

تعریف declarative timerها configuration را reproducible‌تر نشان می‌داد، ولی Caffeine و لغو موقت idle را از کنترل GUI خارج می‌کرد.

تصمیم:

- ظاهر، bar، dock، notification و Polkit declarative؛
- زمان‌بندی lock/display/suspend در writable Noctalia state؛
- Nix آن را force نمی‌کند.

---

# CapsLock دو نقش دارد

Keyd در سطح evdev:

- tap → Escape؛
- hold → Super/Meta.

Niri به Super بسیار متکی است و Neovim workflow از leader استفاده می‌کند. Layer ناوبری Caps حذف شد چون hold را intercept می‌کرد و رفتار اصلی را غیرقابل اعتماد می‌ساخت.

---

# OpenSnitch و Firejail حذف شدند

OpenSnitch در session گرافیکی فعلی prompt قابل اعتمادی نمی‌داد و DNS/proxy را silent drop می‌کرد. Firejail با Box دو مدل sandbox موازی و دو source policy ایجاد می‌کرد.

مانده‌ها:

- firewall ورودی؛
- sudo-rs؛
- AppArmor؛
- USBGuard؛
- Box برای process isolation.

---

# USBGuard باید medium-convenience باشد

هدف home laptop است، نه kiosk. Storage، HID، communication و peripheralهای معمول بدون prompt تکراری کار می‌کنند؛ compositeهای واضح storage+keyboard رد می‌شوند.

Default-deny سخت‌گیرانه به‌خاطر friction و احتمال disable شدن کامل policy رد شد.

---

# Foundation، performance و virtualisation owner جدا دارند

`core.nix` قبلاً foundation، kernel/memory tuning و Podman را هم‌زمان در اختیار داشت. این ترکیب reuse روی host دیگر را مبهم می‌کرد: مصرف‌کننده‌ی locale و Nix cache ناخواسته Zen kernel، zram و container runtime را نیز می‌گرفت.

تصمیم:

- `core.nix`: foundation مشترک؛
- `performance.nix`: kernel، memory، store و storage tuning؛
- `virtualisation.nix`: Podman policy؛
- `hosts/<name>`: bootloader و `system.stateVersion`.

این جداسازی option framework جدید نمی‌سازد و مقدار runtime موجود را عوض نمی‌کند؛ فقط انتخاب policy و review مالکیت را صریح می‌کند.

---

# Podman group عمداً حفظ شده است

Rootless Podman برای کار عادی به گروه `podman` نیاز ندارد، اما این سیستم در مواردی از system/rootful access استفاده می‌کند. بنابراین membership باقی می‌ماند و به‌عنوان privilege مشابه دسترسی مدیریتی مستند می‌شود.

اگر این use case حذف شود، گروه باید دوباره بازبینی شود.

---

# Repository عمومی، secret خصوصی

Repository Public است و تحت MIT منتشر می‌شود، اما visibility به معنی مجاز بودن secret نیست. Password با `passwd`، credentialها با Bitwarden/9router و modelها خارج از Git مدیریت می‌شوند.

CI اولیه source-only است تا کیفیت source را بالا ببرد بدون آن‌که hardware-specific configuration را روی runner عمومی build یا activate کند.

---

# Treesitter را خود Neovim اجرا می‌کند و Nix فقط parser می‌دهد

## مسئله

`nvim-treesitter` در nixpkgs روی شاخه `main` است و ماژول `nvim-treesitter.configs` را ندارد. فراخوانی قدیمی داخل `pcall` بود، پس بی‌صدا شکست می‌خورد: فقط Lua، Markdown و فایل اولِ خط فرمان با Treesitter رنگ می‌شدند (`:checkhealth` و تست روی Neovim 0.12.3 تأیید کرد) و text objectهای مستند‌شده (`daf`, `]f`, swap) اصلاً وجود نداشتند.

## گزینه‌ها

1. بازگشت به شاخه قدیمی `master`؛
2. `:TSInstall` همراه `tree-sitter-cli` و compiler؛
3. شروع Treesitter از `FileType` با parserهای pre-built Nix.

## تصمیم

گزینه ۳. `lua/treesitter.lua` برای هر filetypeای که parser دارد `vim.treesitter.start()` و indent را فعال می‌کند و text objectها را با API جدید می‌بندد. هیچ parser در runtime دانلود یا compile نمی‌شود. Grammarهای Go، Fish و Make هم اضافه شدند، چون gopls/delve و `fish_indent` از قبل config شده بودند ولی Go رنگ نمی‌شد.

## پیامد

`tree-sitter-cli` نصب نمی‌شود (۵۷ MiB)، پس `:checkhealth nvim-treesitter` همچنان `tree-sitter-cli not found` را ERROR نشان می‌دهد؛ این فقط برای نصب parser لازم است و false positive است. `:TSInstall` نباید استفاده شود (parserهای نصب‌شده در `~/.local/share/nvim/site` جای parserهای Nix را می‌گیرند و ممکن است با query ناسازگار باشند). زبان تازه یعنی افزودن grammar به `default.nix`.

## شرط بازنگری

اگر parser بیرون از Nix لازم شد (مثلاً grammar در حال توسعه)، CLI و compiler را فقط در shell همان کار فراهم کنید.

---

# LSP فقط وقتی enable می‌شود که executable دارد

## مسئله

بعد از انتقال serverهای Web/Python به devShell، `vim.lsp.enable` همه‌ی serverها را کورکورانه فعال می‌کرد. lspconfig برای `ts_ls`, `html`, `cssls`, `jsonls`, `tailwindcss` و `yamlls` مقدار `cmd` را function می‌گذارد؛ Neovim نمی‌تواند چنین `cmd`ای را پیش از اجرا بسنجد، پس باز کردن هر `.json`/`.css`/`.html`/`.ts` بیرون از `dev web` یک warning «Spawning language server … failed» می‌داد.

## تصمیم

`lua/lsp.lua` هر server را با `bin` و `shell` توصیف می‌کند و فقط وقتی `executable(bin)` درست است enable می‌کند. بعد از `User DirenvLoaded` (که direnv.vim بعد از export محیط می‌فرستد) دوباره بررسی می‌کند و Neovim serverهای تازه را به bufferهای باز attach می‌کند. `:DevDoctor` می‌گوید برای filetype جاری چه ابزاری هست و کدام devShell آن را دارد.

## پیامد

بیرون از devShell بی‌صدا LSP ندارید (statusline «No LSP» را نشان می‌دهد) و `:checkhealth vim.lsp` دیگر ده‌ها «not executable» ندارد. serverای که فقط در `node_modules/.bin` همان پروژه نصب شده باشد و روی PATH نباشد enable نمی‌شود؛ اگر روزی لازم شد، شرط `executable` باید `node_modules/.bin` را هم ببیند.

---

# debugpy مفسر جدا دارد

## مسئله

hook مربوط به `dev python` عمداً `PYTHONPATH` را unset می‌کند. همین باعث شده بود `python3 -m debugpy.adapter` در همان shell با `No module named 'debugpy'` شکست بخورد؛ یعنی debugger پایتون با config قبلی کار نمی‌کرد.

## گزینه‌ها

1. حذف `unset PYTHONPATH` (آلودگی virtualenvها برمی‌گردد)؛
2. `nvim-dap-python` با `setup("uv")` (بار اول debugpy را از PyPI می‌گیرد، و PyPI پشت proxy همیشه در دسترس نیست)؛
3. مفسر جدا با debugpy، از مسیر مطلق.

## تصمیم

گزینه ۳: `NVIM_DEBUGPY_PYTHON = python3.withPackages [debugpy]` از `dev python` export می‌شود و `dap.lua` آن را هنگام شروع session می‌خواند. کد پروژه همچنان با `.venv` اجرا می‌شود.

## شرط بازنگری

اگر پروژه‌ای debugpy را در `.venv` خودش بخواهد (مثلاً remote attach)، همان config `attach` از پیش پشتیبانی می‌شود.

---

# init.lua از بخش‌های ایزوله ساخته می‌شود

## مسئله

فایل‌های Lua با `builtins.readFile` به یک chunk واحد چسبانده می‌شدند. `if not ok then return end` بالای `snacks.lua`, `completion.lua`, `markdown.lua`, `dap.lua` و `ai.lua` در عمل کل config را پایان می‌داد: اگر فقط یک plugin load نمی‌شد، LSP و formatter و Git هم نمی‌آمدند. هر خطای runtime هم بقیه‌ی فایل‌ها را رد می‌کرد، و سقف ۲۰۰ local در یک chunk (۱۱۶ مصرف‌شده) مانع رشد بود.

## تصمیم

`default.nix` هر فایل را در `section(name, function() … end)` اجرا می‌کند؛ خطا گزارش می‌شود (`config: <file>.lua failed`) و بقیه ادامه می‌دهند. `vim.loader.enable()` هم اول config اجرا می‌شود.

## پیامد

خطاها محلی می‌مانند و startup روی همین سخت‌افزار تست از median حدود ۱۴۱ms به ۸۱ms رسید (زمان `NVIM STARTED` در `--startuptime`، ۱۵ اجرا، headless، پس از warm-up؛ عدد روی لپ‌تاپ شما متفاوت است ولی جهتش یکی است). شماره خط در پیام خطا نسبت به chunk تولیدشده است، نه فایل منبع.

---

# ارتقای Neovim: چیزهایی که عمداً اضافه نشد

## مسئله

بعد از رفع باگ‌ها سه ایده‌ی رایج برای «سریع‌تر و کامل‌تر» روی میز بود: lazy-load بیشتر، نصب `tree-sitter-cli` و map کردن `]]`/`[[` برای referenceها.

## گزینه‌ها

- Lazy-load پلاگین‌های سنگین: حدود ۲۰ms از startup کم می‌کند.
- `tree-sitter-cli`: ۵۷ MiB؛ دو هشدار `:checkhealth` را برمی‌دارد.
- `]]`/`[[` برای reference بعدی/قبلی.

## تصمیم

هیچ‌کدام. هر trigger lazy یک جای تازه برای فراموش‌کردن یک plugin است و ۲۰ms در برابر startup حدود ۸۰ms ارزش این ریسک را ندارد. parserها pre-built از Nix می‌آیند و پوشه‌ی نصب فقط‌خواندنی است، پس `:TSInstall` اصلاً راهی نیست که استفاده شود و CLI فقط یک هشدار را ساکت می‌کند (در جدول health ثبت شده). ftpluginهای Go، Python، Rust، Lua، Markdown و C خودشان `]]`/`[[` را برای function/section می‌گیرند و map سراسری هیچ‌وقت به آن‌ها نمی‌رسد (با gopls آزمایش شد)؛ به‌جایش `]r`/`[r` دارید. `clang-tools` (حدود ۲۰۰ MiB) فقط در `dev build` است، نه در Neovim.

## پیامد

startup و اندازه‌ی closure Neovim ثابت می‌ماند. یک هشدار دائمی `tree-sitter-cli not found` در health می‌ماند.

## شرط بازنگری

اگر startup از ۱۵۰ms (`NVIM STARTED`) گذشت، یا خواستید parser دلخواهی را خودتان با `:TSInstall` بسازید.

---

# چیدمان پوشه‌های home از یک جا می‌آید

## مسئله

بعد از کوتاه‌کردن نام پوشه‌ها (`~/dl`، `~/doc`، `~/media/img`، `~/dev`) دو چیز هنوز به چیدمان قدیمی می‌رفت: screenshotهای niri در `~/Pictures/Screenshots` ذخیره می‌شدند و `~/Projects` در هر switch دوباره ساخته می‌شد. ریشه‌ها: niri و Noctalia (نسخه‌ی 5.0) مسیر پیش‌فرض خودشان را hard-code دارند و `user-dirs.dirs` را نمی‌خوانند؛ Home Manager یک گزینه‌ی `xdg.userDirs.projects` با پیش‌فرض `~/Projects` دارد که `createDirectories` می‌سازد؛ و `extraConfig.XDG_DEV_DIR` با stateVersion جدید به `XDG_XDG_DEV_DIR_DIR` تبدیل می‌شد.

## گزینه‌ها

- فقط `~/Pictures` را برگردانیم: چیدمان کوتاه را کنار می‌گذارد.
- هر config مسیر خودش را بنویسد: همین اتفاق دوباره می‌افتد.
- `xdg.userDirs` تنها منبع باشد و بقیه از آن بخوانند.

## تصمیم

گزینه‌ی سوم. `xdg.nix` همه‌ی پوشه‌ها را تعریف می‌کند (از جمله `projects`، `SCREENSHOTS` و `WALLPAPERS`) و niri، Noctalia، starship و `dev` از `config.xdg.userDirs` می‌خوانند.

## پیامد

پوشه‌ی تازه فقط یک‌جا اضافه یا جابه‌جا می‌شود. پوشه‌های قدیمی خودشان پاک نمی‌شوند؛ انتقال دستی است و در `docs/05-desktop.md` آمده. `~/go` و مسیر عکس guvcview عمداً دست‌نخورده ماندند.

## شرط بازنگری

اگر niri خودش `user-dirs.dirs` را خواند، placeholder در `config.kdl` حذف می‌شود. Noctalia از 5.3 خودش `XDG_PICTURES_DIR` را می‌خواند؛ دو کلیدش را برای زیرپوشه‌های `screenshots` و `wallpapers` نگه داشته‌ایم.

---

# پکیج اختیاری در devShell نباید evaluation را بشکند

## مسئله

nixpkgs گاهی یک dependency را `broken` علامت می‌زند. در ۲۰۲۶-۱۰-۲۳ این برای `oterm` (از راه `fastmcp-slim`) و `open-webui` (از راه `chromadb` ← `posthog`) پیش آمد. یک package خراب کل `dev ai` را از evaluation می‌اندازد و `nix flake check` (یعنی CI) را قرمز می‌کند، در حالی که بقیه‌ی shell سالم است.

## گزینه‌ها

- حذف دائمی دو package: وقتی upstream درست شد برنمی‌گردند.
- `problems.handlers` در nixpkgs برای نادیده‌گرفتن «broken»: package ممکن است build شود و آنجا بشکند.
- `builtins.tryEval`: هر package تا وقتی evaluate می‌شود می‌ماند.

## تصمیم

گزینه‌ی سوم، فقط برای این دو UI اختیاری. اگر evaluate نشد، به‌جایش یک پوشه‌ی خالی می‌آید و banner شل می‌گوید چه چیزی نیست.

## پیامد

Update با یک package خراب upstream متوقف نمی‌شود. بهایش غیبت بی‌صدای ابزار است؛ banner و `ai-doctor` آن را نشان می‌دهند. این الگو را برای ابزار اصلی به کار نبرید.

## شرط بازنگری

اگر nixpkgs هر دو package را درست کرد و چند هفته پایدار ماند، `tryEval` برداشته می‌شود.

---

# قالب تصمیم جدید

برای افزودن ADR:

```markdown
# عنوان تصمیم

## مسئله
چه چیزی عملاً خراب، کند یا مبهم بود؟

## گزینه‌ها
چه راه‌هایی بررسی شدند؟

## تصمیم
کدام راه انتخاب شد و چرا؟

## پیامد
چه چیزی بهتر و چه چیزی سخت‌تر شد؟

## شرط بازنگری
با چه evidenceای باید تصمیم دوباره بررسی شود؟
```

Decision log جای comment نزدیک کد را نمی‌گیرد. Comment باید «چرا این خط اینجاست» را بگوید؛ ADR trade-off کل سیستم را.

---

بازگشت به [فهرست مستندات](README.md).
