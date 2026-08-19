# ۰۹ — قواعد عملیاتی و مهندسی Repository

این فصل تله‌های deployment و قراردادهای تغییر source را نگه می‌دارد. قاعده‌ای که فقط در حافظه باشد دیر یا زود شکسته می‌شود.

---

# شبکه‌ی محدود و sourceهای بدون cache

## سه مسیر دانلود متفاوت

| محتوا | معمولاً از کجا | چه کسی دانلود می‌کند؟ |
| :--- | :--- | :--- |
| binary substitute | cache.nixos.org / Cachix | nix-daemon |
| source fetcher در build | GitHub/Codeberg/NVIDIA/... | nix-daemon |
| command تعاملی | URL دلخواه | shell process |

Proxy shell روی daemon اثر ندارد. Proxy daemon نیز الزاماً application تعاملی را proxy نمی‌کند.

## Scope ابزارها

```text
proxy_on   → shell جاری
px         → یک command
nix_proxy  → nix-daemon تا off یا reboot
box --proxy→ environment داخل Box
```

---

# Codeberg و pluginهای DAP

بعضی pluginهای Neovim source مستقیم دارند و اگر cache miss شود، daemon باید Codeberg را ببیند.

## نصب اولیه‌ی مرحله‌ای

اگر build اولیه روی DAP source شکست خورد، موقتاً packageهای مربوط را در `modules/home/dev/nvim/default.nix` comment کنید:

```nix
# nvim-dap
# nvim-dap-ui
# nvim-dap-virtual-text
# nvim-dap-python
# one-small-step-for-vimkind
```

Lua setup با `pcall` محافظت شده و نبودن plugin startup کل editor را نمی‌شکند.

سیستم پایه را build/activate کنید، سپس daemon proxy را روشن و packageها را برگردانید:

```bash
nix_proxy 1819
bld
# پس از build موفق و تست مورد نظر
nix_proxy off
```

در build اولیه می‌توان از `nixos-rebuild` خام استفاده کرد. این docs هیچ activation خودکاری اجرا نمی‌کند.

## چرا `HTTP_PROXY=... sw` کافی نیست؟

`nixos-rebuild` درخواست build را به daemon می‌دهد. Daemon service environment مستقل دارد. `nix_proxy` drop-in موقت را زیر `/run` می‌سازد و service را restart می‌کند.

بعد از کار:

```bash
nix_proxy status
nix_proxy off
```

Proxy daemon را روشن و فراموش نکنید؛ رفتار موقت و قابل مشاهده هدف طراحی است.

---

# NVIDIA source

Driver proprietary ممکن است هنگام cache miss از download.nvidia.com دریافت شود. URL دقیق به version package pinned در nixpkgs وابسته است؛ مثال placeholder را به‌عنوان URL واقعی اجرا نکنید.

روند diagnosis:

1. error build و URL دقیق را بخوانید؛
2. daemon proxy را در صورت نیاز فعال کنید؛
3. یا همان URL دقیق را با shell proxy prefetch کنید؛
4. hash و store result را با build مورد انتظار تطبیق دهید؛
5. build را تکرار کنید.

```bash
proxy_on 1819
nix-prefetch-url --type sha256 'URL-FROM-THE-ACTUAL-BUILD-ERROR'
proxy_off
```

Prefetch کردن فایل دیگری با version مشابه build را حل نمی‌کند. URL و hash باید دقیقاً همان derivation باشند.

---

# DNS owner را عوض نکن

قرارداد فعلی:

```text
/etc/resolv.conf → 127.0.0.1
NetworkManager DNS = none
dnscrypt-proxy = owner upstream/fallback
resolved = disabled
resolvconf = disabled
```

Fallback باید داخل DNS tool باشد. افزودن nameserver خارجی به `/etc/resolv.conf` این قرارداد را می‌شکند و query می‌تواند DNSCrypt را bypass کند.

قبل از تغییر DNS:

```bash
dig @127.0.0.1 example.com A
systemctl status dnscrypt-proxy
journalctl -u dnscrypt-proxy -b --no-pager
```

---

# تغییر network را از diagnosis جدا کن

ابزارهای `dev net` service نیستند. اجرای `nmap` یا `testssl` setting سیستم را عوض نمی‌کند؛ اجرای proxy core با config مشخص process runtime است؛ تغییر `modules/nixos/network.nix` policy نسل سیستم است.

در این مرحله موارد زیر بدون use case و تست تغییر نمی‌کنند:

- IPv6 policy؛
- IP forwarding؛
- DNS owner؛
- resolver filterها؛
- NetworkManager ownership؛
- firewall default.

---

# مالکیت package

## Global بماند اگر

- تقریباً هر روز استفاده می‌شود؛
- در recovery/diagnosis لازم است؛
- desktop association یا preview به آن وابسته است؛
- ورود به shell برای استفاده از آن friction غیرمنطقی می‌سازد.

## DevShell باشد اگر

- language/project-specific است؛
- closure سنگین دارد؛
- audit/media/profiling نادر است؛
- debugger/compiler فقط در project لازم است؛
- service/model/toolchain نباید دائماً global باشد.

Overlap محدود برای self-contained بودن Neovim یا shell قابل قبول است. Nix store محتوای یکسان را دوباره ذخیره نمی‌کند. هدف حذف هر occurrence تکراری نیست؛ هدف owner روشن است.

---

# افزودن package

Checklist:

```text
[ ] binary دقیق package را می‌شناسم؟
[ ] daily است یا project-specific؟
[ ] package مشابه موجود نیست؟
[ ] unfree/insecure/network consequence دارد؟
[ ] docs و XDG association لازم است؟
[ ] closure سنگین است؟
[ ] در Neovim wrapper هم لازم است یا PATH global کافی است؟
```

جست‌وجو:

```bash
nix search nixpkgs package-name
nix-locate --minimal --whole-name bin/binary-name
```

Package را فقط چون نامش مدرن است اضافه نکنید؛ سؤال و workflow مشخص بنویسید.

---

# افزودن NixOS module

مالکیت را قبل از فایل تعیین کنید:

| موضوع | محل |
| :--- | :--- |
| device/filesystem/bus ID | `hosts/<name>` یا hardware module |
| policy مشترک سیستم | `modules/nixos` |
| user program/config | `modules/home` |
| project toolchain | `shells` |
| mutable project isolation | Box/runtime state |

Module کوچک و explicit از option framework بدون caller بهتر است. اگر دو host/user واقعاً variation دارند، آن زمان option یا profile مشترک بسازید.

بعد از import:

```bash
rg -n 'new-module' hosts users modules
```

Docs overview و template مرتبط را update کنید.

---

# افزودن host

```bash
cp -r hosts/_template hosts/new-host
```

سپس:

1. hardware config واقعی؛
2. hostname و Flake output؛
3. bootloader؛
4. `system.stateVersion` نصب اولیه؛
5. profileهای سازگار؛
6. userها؛
7. CPU/GPU/network assumptions.

NVIDIA bus ID و filesystem host قبلی را reuse نکنید.

---

# افزودن user

```bash
cp -r users/_template users/new-user
rg -n 'username|/home/username' users/new-user
```

System-side و Home-side دو فایل جدا دارند. Login shell و group در NixOS؛ program/config و Home stateVersion در Home Manager.

Password mutable است و با `passwd` مدیریت می‌شود. Password/hash را به repository یا Age secret جدید اضافه نکنید.

---

# افزودن devShell

```bash
cp -r shells/_template shells/example
```

Shell باید:

- نام کوتاه و ثابت؛
- icon/description تک‌خطی؛
- packageهای اختصاصی؛
- tipهای واقعی؛
- hook بدون side effect سنگین؛
- احترام به non-interactive و `DEVSHELL_QUIET`.

Registry:

1. نام در `shellDirs`؛
2. دقیقاً یک group؛
3. alias معتبر و بدون collision؛
4. docs فصل ۰۳؛
5. completion/consistency check.

ورود shell نباید service شروع، model دانلود یا project را تغییر دهد.

---

# تغییر `dev`

Interface موجود compatibility contract است:

```text
dev ENV [COMMAND...]
dev -i
dev -w ENV
dev --keep ENV
dev --roots
dev --unkeep ENV
dev --prune
```

قاعده‌ها:

- command عادی separator اجباری نمی‌خواهد؛
- cleanup confirmation و failure-safe می‌ماند؛
- daemon query failure حذف ایجاد نمی‌کند؛
- root واقعی باید با registry daemon اثبات شود؛
- Bash/Fish/Zsh completion هم‌زمان update شوند؛
- menu سریع Flake evaluation انجام نمی‌دهد.

Structured subcommand، doctor، JSON report و featureهای اضافی بدون نیاز واقعی اضافه نمی‌شوند.

---

# تغییر Box

Invariantهای غیرقابل شکستن:

1. `$PWD` خودکار mount نمی‌شود؛
2. `.box/work` default خصوصی است؛
3. `.box/tmp → /tmp` در persistent mode حفظ می‌شود؛
4. `.box/<name> → /<name>` حفظ می‌شود؛
5. `-s` read-only و `-S` read-write می‌ماند؛
6. `--secure` network را قطع نمی‌کند؛
7. network فقط با option network کنترل می‌شود؛
8. explicit invalid input باید error باشد؛
9. dry-run فایل/process ایجاد نمی‌کند؛
10. caller PATH برای ترکیب با devShell حفظ می‌شود.

قبل از patch:

```bash
bash -n modules/home/dev/box/box.sh
git diff --check
```

Runtime test بعداً و روی ماشین دارای Bubblewrap انجام می‌شود.

---

# تغییر Desktop و keybinding

1. implementation را در `config.kdl` تغییر دهید؛
2. conflict با binding موجود را جست‌وجو کنید؛
3. `docs/keys.md` را همان commit update کنید؛
4. keyd و Niri layer را قاطی نکنید؛
5. lock fallback و shortcut مفید را حذف نکنید؛
6. idle GUI/Caffeine را declarative force نکنید.

جست‌وجو:

```bash
rg -n 'Mod\+|XF86|CapsLock|overload' \
  modules/home/gui/niri modules/nixos/keyd.nix docs/keys.md
```

---

# تغییر Neovim

- plugin package و executable dependency در `default.nix`؛
- behavior در Lua file موضوعی؛
- key زیر گروه semantic موجود؛
- description برای which-key؛
- shortcut docs؛
- LSP/debugger سنگین در project shell، مگر استفاده روزمره دلیل global بودن باشد؛
- generated AI command قبل از اجرا قابل review باشد؛
- plugin گمشده startup کامل را خراب نکند.

کانفیگ portable/Lazy migration یک refactor مستقل است و نباید با cleanup کوچک مخلوط شود.

---

# Secret و repository عمومی

قبل از commit:

```bash
git diff --cached --check
git diff --cached | rg -n -i \
  'api[_-]?key|token|password|secret|private[_-]?key'
dev audit audit-repo .
```

Scanner جای review انسانی را نمی‌گیرد.

اگر secret واقعی commit شد:

1. rotate/revoke؛
2. scope exposure؛
3. source cleanup؛
4. history decision؛
5. report امن طبق `SECURITY.md`.

Public بودن repository با private بودن credentialها تناقض ندارد.

---

# Source-only CI

CI اولیه مجاز است:

- formatting؛
- static lint؛
- shell syntax؛
- Markdown/YAML؛
- secret scan؛
- Registry/completion/docs invariant؛
- action workflow lint.

CI اولیه مجاز نیست:

- Flake evaluation؛
- Nix build؛
- NixOS activation؛
- service start؛
- hardware/runtime test؛
- model download.

سبز بودن CI فقط source quality را ثابت می‌کند.

---

# Git و commit

Commit باید یک هدف قابل توضیح داشته باشد:

```text
fix(box): validate explicit proxy ports
refactor(dev): split root and completion ownership
docs(cli): add robust search and transfer recipes
ci: add source-only quality gates
```

قبل از commit:

```bash
git status --short
git diff --check
git diff --stat
git diff
git diff --cached
```

بعد از commit:

```bash
git show --stat --summary HEAD
git status --short
```

Patch استاندارد:

```bash
git format-patch --output-directory patches BASE..HEAD
```

Patchها باید به ترتیب apply شوند و هر commit مستقل قابل review باشد.

---

# پنج اصل نهایی

1. **Owner روشن‌تر از abstraction بیشتر است.**
2. **Failure مشاهده نباید destructive action تولید کند.**
3. **Workflow روزمره قربانی closure مینیمال نمی‌شود.**
4. **کد نامطمئن حداقل share و privilege را می‌گیرد.**
5. **Source check، build و runtime سه سطح جدا هستند.**

---

بعدی: [۱۰ تصمیم‌های معماری](10-decisions.md)
