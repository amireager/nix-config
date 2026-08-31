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

# Nix-check آینه‌ی CI است

`nix-check` همان پنج گام CI را با همان ترتیب اجرا می‌کند: `nix flake check` (eval کامل)، alejandra از طریق formatter خود Flake، statix، deadnix و `bash -n`. منطق این است که «سبز محلی = سبز CI»؛ شکستن evaluation قبل از push دیده می‌شود، نه بعد از یک run قرمز.

هر چک دقیقاً یک صاحب دارد: این پنج گام فقط در CI و آینه‌ی محلی‌اش تعریف می‌شوند. Build و activation همچنان مرز صریح کاربرند و در هیچ‌کدام اجرا نمی‌شوند.

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
