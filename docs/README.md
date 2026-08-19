# راهنمای کامل NixOS Workstation

این repository یک سیستم واقعی و روزمره را توصیف می‌کند: از bootloader و driver تا shell، editor، desktop، sandbox و محیط‌های توسعه. هدف آن نمایش چند snippet مستقل نیست؛ هدف این است که هر generation از روی source قابل بازسازی، بررسی و بازگشت باشد.

ورودی انگلیسی برای مخاطب بین‌المللی در [`../README.md`](../README.md) است. این handbook مرجع کامل فارسی پروژه است.

---

# این پروژه برای چه کسی است؟

سه گروه می‌توانند از آن استفاده کنند:

1. **مالک سیستم:** برای نصب، update، recovery و یادآوری تصمیم‌ها؛
2. **مشارکت‌کننده:** برای فهمیدن مالک هر تنظیم و قراردادهای تغییر؛
3. **خواننده‌ی بیرونی:** برای دیدن یک نمونه‌ی واقعی از ترکیب NixOS، Home Manager، Niri، devShell و sandbox.

این config یک starter عمومی نیست. سخت‌افزار، GPU bus ID، bootloader، username، timezone و سیاست شبکه شخصی‌اند. ساختار قابل اقتباس است، ولی deploy مستقیم روی ماشین دیگر بدون review خطرناک است.

---

# مشخصات سیستم هدف

| بخش | مقدار |
| :--- | :--- |
| میزبان | Acer Aspire A715-42G |
| CPU | AMD Ryzen 5 5500U، Lucienne / Zen 2 |
| GPU | AMD iGPU + Nvidia GTX 1650 Mobile TU117 |
| معماری | `x86_64-linux` |
| Kernel | `linuxPackages_zen` |
| NVIDIA | proprietary module، `open = false`، Prime offload |
| Desktop | Niri + Noctalia روی Wayland |
| Login | SDDM روی Wayland |
| User management | NixOS + Home Manager یکپارچه |
| Shell | Fish، با completion برای Bash/Zsh |
| Editor | Neovim 0.11+ با plugin/LSP/DAP declarative |
| Container | Podman، شامل دسترسی rootful مورد استفاده |
| Sandbox | Bubblewrap از طریق `box` |

---

# سیستم چه چیزهایی را مدیریت می‌کند؟

## سیستم‌عامل و سخت‌افزار

- bootloader و generationهای systemd-boot؛
- Zen kernel، initrd، ZRAM و OOMD؛
- firmware، SMART، fstrim و journal limits؛
- NVIDIA Prime offload و power management؛
- power/lid/battery policy لپ‌تاپ؛
- CapsLock در سطح evdev با keyd.

## شبکه و امنیت

- NetworkManager بدون مالکیت DNS؛
- `/etc/resolv.conf` ثابت به DNSCrypt روی loopback؛
- fallback resolver داخل DNSCrypt، نه خارج آن؛
- proxychains و helperهای proxy در چند scope؛
- firewall ورودی بدون port عمومی؛
- sudo-rs، AppArmor، USBGuard و fwupd؛
- Box برای processهایی که نباید Home واقعی را ببینند.

## محیط کاربر

- Fish، Starship، Git، tmux و Zellij؛
- ابزارهای جست‌وجو، داده، HTTP، دانلود و diagnosis؛
- Kitty و WezTerm؛
- browser، media و XDG associationها؛
- Niri config، Fuzzel helperها و Noctalia.

## توسعه

- دوازده devShell on-demand؛
- command سراسری `dev` با root واقعی؛
- Neovim، LSP، formatter، DAP، REPL، Git و AI؛
- Box به‌عنوان sandbox مستقل از devShell؛
- audit ابزارهای secret/CVE/SBOM/hardening.

---

# مرز declarative و mutable

Nix مالک همه‌ی stateها نیست و نباید هم باشد. mutable zoneهای عمدی:

| مسیر/بخش | مالک | دلیل |
| :--- | :--- | :--- |
| Noctalia GUI state | Noctalia | idle/Caffeine باید runtime قابل تغییر باشد |
| `~/.local/share/dev-roots` | `dev` | profile، GC-root و last-used |
| `<project>/.box` | Box | Home/work/tmp خصوصی هر پروژه |
| `/run/systemd/system/...nix-proxy...` | `nix_proxy` | proxy موقت daemon تا reboot |
| login password | `passwd` | secret در Git/Agenix قرار نمی‌گیرد |
| API credentialها | Bitwarden/9router | جدا از public repository |
| AI modelها | storage کاربر | بزرگ، mutable و خارج از Git |

این مرزها در docs ثبت شده‌اند تا state پنهان یا تصادفی نباشد.

---

# مسیر مطالعه

## اگر تازه وارد پروژه شده‌اید

1. [۰۱ نمای کلی](01-overview.md)
2. [۰۳ محیط‌های توسعه](03-dev.md)
3. [۰۴ جعبه‌ابزار CLI](04-cli.md)
4. [۰۸ Box و Audit](08-sandbox.md)
5. [۱۰ تصمیم‌ها](10-decisions.md)

## اگر می‌خواهید سیستم را نصب یا نگه‌داری کنید

1. همین صفحه، بخش نصب؛
2. [۰۲ عملیات Nix](02-nix.md)؛
3. [۰۹ قواعد عملیاتی](09-rules.md)؛
4. [۰۵ Desktop](05-desktop.md)؛
5. [مرجع کلیدها](keys.md).

## اگر توسعه‌دهنده‌اید

1. [۰۳ محیط‌ها](03-dev.md)؛
2. [۰۴ CLI](04-cli.md)؛
3. [۰۶ Neovim](06-editor.md)؛
4. [۰۷ AI](07-ai.md)؛
5. [`../CONTRIBUTING.md`](../CONTRIBUTING.md).

---

# فهرست فصل‌ها

| فصل | پرسشی که جواب می‌دهد |
| :--- | :--- |
| [۰۱ نمای کلی](01-overview.md) | Flake، host، user و moduleها چطور به هم وصل‌اند؟ |
| [۰۲ عملیات Nix](02-nix.md) | چطور امن build/update/clean/rollback کنیم؟ |
| [۰۳ محیط‌های توسعه](03-dev.md) | هر shell چه دارد و چگونه اجرا/حفظ می‌شود؟ |
| [۰۴ CLI](04-cli.md) | ابزارهای روزمره را چطور حرفه‌ای ترکیب کنیم؟ |
| [۰۵ Desktop](05-desktop.md) | Niri/Noctalia و workflow گرافیکی چگونه کار می‌کنند؟ |
| [۰۶ Editor](06-editor.md) | Neovim، LSP، DAP، REPL و Git چگونه به کار می‌روند؟ |
| [۰۷ AI](07-ai.md) | gateway، local inference و editor AI چه مرزی دارند؟ |
| [۰۸ Sandbox](08-sandbox.md) | Box چه چیزی را مخفی می‌کند و چه چیزی را نمی‌کند؟ |
| [۰۹ قواعد](09-rules.md) | تله‌های شبکه/driver و قرارداد تغییر repository چیست؟ |
| [۱۰ تصمیم‌ها](10-decisions.md) | چرا این راه انتخاب شد و چه راه‌هایی رد شدند؟ |
| [مرجع کلیدها](keys.md) | برای یک کار مشخص چه کلیدی بزنم؟ |

---

# نصب روی NixOS خام

> این دستورات نمونه‌ی deployment هستند و روی ماشین هدف build/activation انجام می‌دهند. قبل از اجرا hardware و user را شخصی‌سازی کنید.

## ۱. checkout و symlink پایدار

```bash
nix-shell -p git

git clone https://github.com/amireager/nix-config "$HOME/nix-config"
sudo ln -sfn "$HOME/nix-config" /etc/nixos
readlink -f /etc/nixos
cd /etc/nixos
```

چرا symlink؟ مسیر واقعی project می‌تواند تغییر کند، ولی `nh`، `nrf`، Audit و recovery همیشه `/etc/nixos` را می‌شناسند.

## ۲. hardware config

```bash
sudo nixos-generate-config --show-hardware-config > hosts/nixos/hardware.nix
```

فقط replace کردن `hardware.nix` کافی نیست. این موارد را هم بررسی کنید:

- filesystem و swap؛
- bootloader؛
- CPU/GPU driver؛
- NVIDIA bus IDها؛
- laptop-only moduleها؛
- hostname و stateVersion.

## ۳. user

پوشه‌ی template را کپی و تمام occurrenceهای username/home را عوض کنید:

```bash
cp -r users/_template users/myuser
rg -n 'username|/home/username' users/myuser
```

سپس user را در call مربوط به `lib.mkHost` ثبت کنید.

## ۴. host

برای ماشین جدید:

```bash
cp -r hosts/_template hosts/myhost
```

Moduleهای laptop/NVIDIA/desktop را فقط در صورت سازگاری فعال کنید. `system.stateVersion` نسخه‌ی نصب اولیه است و بعداً برای دنبال‌کردن release تغییر نمی‌کند.

## ۵. شبکه‌های محدود

بعضی sourceها مانند Codeberg یا NVIDIA ممکن است مستقیم در دسترس نباشند. راهنمای مرحله‌ای و تفاوت proxy shell با proxy daemon در [۰۹ قواعد](09-rules.md) آمده است.

## ۶. build قبل از switch

```bash
nh os build
nh os test
nh os switch
```

برای نصب اولیه ممکن است `nixos-rebuild` خام لازم باشد. جزئیات recovery در [۰۲](02-nix.md) است.

---

# استفاده‌ی روزمره در پنج دقیقه

```bash
# سیستم
git -C /etc/nixos status --short
bld
tst
sw

# محیط پروژه
dev -i
dev python python -m pytest -q
dev --roots

# sandbox
box --dry-run --secure command
box --secure --net none command

# جست‌وجو
rg -n --hidden -g '!.git' 'pattern'
rg --files | fzf

# editor
nvim project-file
# Space را بزنید و which-key را بخوانید
```

---

# اصول ثابت پروژه

1. **منبع حقیقت دوم نساز.** proxy، shell registry، key docs و package owner باید روشن باشند.
2. **ابزار روزمره را به زور on-demand نکن.** کاهش closure نباید workflow را خراب کند.
3. **environment نباید هنگام ورود side effect سنگین داشته باشد.** service و model download دستی‌اند.
4. **کد نامطمئن Home واقعی را نمی‌بیند.** Box project را هم خودکار mount نمی‌کند.
5. **runtime state لازم را declarative جعل نکن.** Caffeine، roots و project sandbox state مالک مشخص دارند.
6. **source check را با runtime validation اشتباه نگیر.** parser موفق، boot سالم را ثابت نمی‌کند.
7. **دلیل تصمیم عجیب را بنویس.** ADR از تکرار شکست قبلی جلوگیری می‌کند.

---

# درباره‌ی نویسندگی و AI

این سیستم با کمک مدل‌ها و agentهای مختلف ساخته و بازبینی شده است. نقش مالک repository تعریف هدف، انتخاب trade-off، تست روی سخت‌افزار واقعی، رد پیشنهادهای نامناسب و نگه‌داری تصمیم‌هاست.

کد تولیدشده صرفاً به‌خاطر تولیدشدن پذیرفته نمی‌شود. نمونه‌های مهمی که راه اول رد شد—از command-not-found تا AI completion و Box Home-Swap—در [۱۰ تصمیم‌ها](10-decisions.md) ثبت شده‌اند.

---

# ادامه

از [۰۱ — نقشه‌ی معماری](01-overview.md) شروع کنید.
