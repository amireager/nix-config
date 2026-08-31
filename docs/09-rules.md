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
nix_proxy test 1819
nix_proxy on 1819
nrb
# پس از build موفق و تست مورد نظر
nix_proxy off
```

در build اولیه می‌توان از `nixos-rebuild` خام استفاده کرد. این docs هیچ activation خودکاری اجرا نمی‌کند.

## چرا `HTTP_PROXY=... nrs` کافی نیست؟

`nixos-rebuild` درخواست build را به daemon می‌دهد. Daemon service environment مستقل دارد. `nix_proxy` drop-in موقت را زیر `/run` می‌سازد و service را restart می‌کند.

بعد از کار:

```bash
nix_proxy status
nix_proxy off
```

Proxy daemon را روشن و فراموش نکنید؛ رفتار موقت و قابل مشاهده هدف طراحی است.

---

# NVIDIA source

Driver proprietary ممکن است هنگام cache miss از download.nvidia.com دریافت شود. URL دقیق به version package pinned در nixpkgs وابسته است؛ مثال placeholder را به‌عنوان URL واقعی اجرا نکنید. ابتدا `nix_proxy test` را بررسی کنید و فقط در صورت نیاز daemon را موقتاً proxy کنید.

Prefetch کردن فایل دیگری با version مشابه build را حل نمی‌کند. URL، hash، mode و Store name باید دقیقاً همان derivation باشند.

## بازیابی دستی یک fixed-output حجیم

این مسیر برای failure نادر است و هیچ hook یا cache سراسری به Nix اضافه نمی‌کند. partial اولین تلاش Nix معمولاً قابل استفاده نیست؛ دانلود دستی یک بار از ابتدا شروع می‌شود، اما قطع‌های بعدی با همان فایل ادامه پیدا می‌کنند.

### ۱. derivation را بدون build بررسی کنید

مسیر `.drv` را فقط از error واقعی بردارید:

```bash
drv='/nix/store/…-source.drv'
nix derivation show "$drv" |
  jq 'to_entries[0].value
    | {
        name,
        outputs,
        urls: (.structuredAttrs.urls // .env.urls // .env.url // null),
        postFetch: (.structuredAttrs.postFetch // .env.postFetch // null)
      }'

nix-store --query --outputs "$drv"
```

فقط وقتی ادامه دهید که:

- دقیقاً یک output وجود دارد؛
- method در schema جدید `flat` است؛ در schema قدیمی `hashAlgo` با `r:` شروع نمی‌شود؛
- hash و URL مستقیم HTTP(S) مشخص‌اند؛
- `postFetch`، unpack یا transform وجود ندارد؛
- output مورد انتظار یک فایل است، نه directory.

`fetchzip`، Git، خروجی `nar`/recursive و derivation چندخروجی این recipe را ندارند.

### ۲. همان URL را resumable دانلود کنید

```bash
work="$HOME/Downloads/nix-recovery"
file="$work/source.part"
url='URL-FROM-THE-ACTUAL-BUILD-ERROR'
install -d -m 700 "$work"

curl --fail --show-error --location --continue-at - \
  --retry 8 --retry-delay 2 --retry-connrefused \
  --connect-timeout 30 \
  --output "$file" \
  "$url"
```

برای proxy محلی فقط command دانلود را عوض کنید؛ فایل همان است:

```bash
curl --proxy "socks5h://$PROXY_HOST:$PROXY_PORT" \
  --fail --show-error --location --continue-at - \
  --retry 8 --retry-delay 2 --retry-connrefused \
  --connect-timeout 30 \
  --output "$file" \
  "$url"
```

اگر server از HTTP Range پشتیبانی کند، اجرای دوباره از اندازه‌ی فعلی ادامه می‌دهد. تغییر mirror فقط وقتی مجاز است که دقیقاً همان bytes و hash را ارائه کند.

### ۳. Store path را پیش از import تطبیق دهید

الگوریتم را از hash derivation بردارید؛ برای مثال `sha256`. سپس نام Store را از output مورد انتظار بگیرید:

```bash
expected="$(nix-store --query --outputs "$drv")"
base="${expected##*/}"
name="${base#*-}"
algo='sha256'  # دقیقاً مطابق derivation

candidate="$(nix store add --dry-run \
  --mode flat \
  --hash-algo "$algo" \
  --name "$name" \
  "$file")"

printf 'expected:  %s\ncandidate: %s\n' "$expected" "$candidate"
test "$candidate" = "$expected"
```

`--dry-run` محتوا را hash می‌کند ولی چیزی وارد Store نمی‌کند. اگر دو path یکسان نیستند، فایل را import نکنید: URL، bytes، mode، الگوریتم یا name اشتباه است.

### ۴. فقط با command رسمی Nix وارد Store کنید

```bash
added="$(nix store add \
  --mode flat \
  --hash-algo "$algo" \
  --name "$name" \
  "$file")"

if test "$added" = "$expected" && nix path-info "$expected"; then
  rm -f -- "$file" "$file.aria2"
  rmdir --ignore-fail-on-non-empty "$work"
else
  printf 'imported path did not validate; keep the source file\n' >&2
fi
```

هرگز با `sudo cp`، تغییر permission یا دست‌کاری database چیزی را مستقیم زیر `/nix/store` قرار ندهید. فقط وقتی branch موفق اجرا شد command اصلی Nix را دوباره اجرا کنید؛ output معتبر از قبل در Store است. path اشتباه importشده root ندارد و بعداً با GC عادی قابل پاک‌شدن است.

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
| device/filesystem/bus ID، bootloader، stateVersion | `hosts/<name>` یا hardware module |
| foundation مشترک | `modules/nixos/core.nix` |
| kernel/memory/store tuning | `modules/nixos/performance.nix` |
| container runtime | `modules/nixos/virtualisation.nix` |
| network/security/desktop policy | module موضوعی در `modules/nixos` |
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
- registration واقعی باید هنگام ورود synchronous باشد و failure را پنهان نکند؛
- menu وضعیت را از `gc-root` محلی می‌خواند و daemon-wide query انجام نمی‌دهد؛
- Bash/Fish/Zsh completion هم‌زمان update شوند؛
- menu سریع Flake evaluation انجام نمی‌دهد؛
- `runtime.nix` interface/launch، `roots.nix` lifecycle و `completions.nix` shell integration را مالک‌اند؛
- Registry باید validity، membership، group، alias target و collision را قبل از تولید output رد کند؛
- metadata در `passthru.devShellMeta` می‌ماند و output سفارشی top-level ساخته نمی‌شود.

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

# CI — گیت eval و lint

CI فعلی (GitHub Actions) هر push را با این گام‌ها می‌سنجد:

- نسل‌شناسی flake.lock (flake-checker)؛
- Flake evaluation کامل: `nix flake check` شامل home-manager و همه‌ی devShellها؛
- formatting از طریق output `formatter` خود Flake (alejandra)؛
- static lint: statix و deadnix؛
- shell syntax: `bash -n` روی `*.sh`های tracked؛
- lint خود workflow و ارتقای نسخه‌ی actionها با dependabot.

CI انجام نمی‌دهد:

- Nix build؛
- NixOS activation؛
- service start؛
- hardware/runtime test؛
- model download؛
- secret scan (ابزارش در شل `audit` است و اجرای دوره‌ای‌اش دست کاربر).

سبز بودن CI یعنی کل Flake eval می‌شود و source تمیز است؛ سلامت runtime را ثابت نمی‌کند.

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
