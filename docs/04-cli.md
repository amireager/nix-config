# ۰۴ — خط فرمان: Fish و جعبه‌ابزار عملیاتی

این فصل فقط نام ابزارها را ردیف نمی‌کند. هدف این است که معلوم شود **چه ابزاری برای چه سؤال عملی انتخاب می‌شود** و چطور چند ابزار کوچک را به یک pipeline قابل اعتماد تبدیل کنیم.

قاعده‌ی مثال‌ها:

- commandهای read-only آزادانه نشان داده می‌شوند؛
- commandهای تغییردهنده ابتدا با preview، `--dry-run` یا `git diff` همراه‌اند؛
- برای نام فایل‌های دارای فاصله، از delimiter صفر (`-0`) استفاده می‌شود؛
- regex و variableها quote می‌شوند؛
- پیچیدگی فقط وقتی اضافه می‌شود که failure mode واقعی را حل کند.

---

## Fish — رابط اصلی خط فرمان

Fish shell اصلی کاربر است. Bash و Zsh برای compatibility و completion پشتیبانی می‌شوند، اما تنظیمات تعاملی روزانه حول Fish طراحی شده‌اند.

### Abbreviation به‌جای alias پنهان

Abbreviation قبل از اجرا روی خط فرمان باز می‌شود. بنابراین `sw` به شکل واقعی `nh os switch` دیده می‌شود و command تغییردهنده پنهان نمی‌ماند.

| مخفف | باز می‌شود به |
| :--- | :--- |
| `sw` / `tst` / `bld` | `nh os switch` / `test` / `build` |
| `nrs` / `nrt` / `nrb` | نام دوم همان سه عملیات |
| `nrf` | مسیر recovery با `nixos-rebuild --flake /etc/nixos#nixos` |
| `gs` / `ga` / `gc` | status، add و commit |
| `gco` / `gcb` / `gsw` | checkout، ساخت branch و switch |
| `gp` / `gpl` | push و pull با rebase |
| `n` | `nvim` |
| `myip` | آدرس خروجی اینترنت با `curl ip.me` |

### Aliasهایی که واقعاً جایگزین command هستند

| دستور | پیاده‌سازی |
| :--- | :--- |
| `ls` | `eza` با icon، Git status و directory-first |
| `ll` | long listing همراه header |
| `la` | long listing شامل فایل‌های مخفی |
| `lt` | tree با عمق دو |
| `tree` | tree کامل با icon و Git status |
| `cat` | `bat --style=plain` |
| `top` | `btop` |

برای scriptها روی alias حساب نکنید؛ command واقعی را بنویسید. Aliasها فقط رابط تعاملی‌اند.

### Keybinding

`Ctrl+Space` پیشنهاد فعلی autosuggestion را می‌پذیرد. این binding با Niri یا Neovim برخورد ندارد.

---

## توابع محلی این repository

### `proxy_on` و `proxy_off` — پروکسی همین shell

```bash
proxy_on             # host/port پیش‌فرض lib.proxy
proxy_on 8080        # port صریح، فقط 1..65535
proxy_off
```

این تابع نسخه‌های uppercase و lowercase متغیرهای HTTP/HTTPS/FTP/ALL proxy را تنظیم می‌کند. `NO_PROXY` آدرس‌های loopback را مستقیم نگه می‌دارد.

بررسی:

```bash
env | rg -i '^(all|http|https|no)_proxy='
myip
proxy_off
```

### `px` — فقط یک command از proxychains

```bash
px curl --fail-with-body https://example.com
PROXY_PORT=8080 px xh GET https://api.example.com/status
```

اگر `PROXY_PORT` وجود داشته باشد، `px` یک config موقت permission-600 می‌سازد، فقط endpoint محلی SOCKS را عوض می‌کند، command را اجرا می‌کند و status واقعی آن را برمی‌گرداند.

این روش برای command منفرد بهتر از `proxy_on` است، چون environment shell را آلوده نمی‌کند.

### `nix_proxy` — پروکسی موقت daemon

```bash
nix_proxy status
nix_proxy test        # listener و خروجی واقعی، بدون تغییر daemon
nix_proxy on          # port پیش‌فرض یا PROXY_PORT
nix_proxy on 1819     # port صریح
nix_proxy 1819        # فرم کوتاه
nix_proxy off
```

`nix-daemon` environment ترمینال را ارث نمی‌برد. ابزار یک drop-in موقت زیر `/run/systemd/system/nix-daemon.service.d` می‌نویسد و پس از restart، service و `ALL_PROXY` مؤثر را بررسی می‌کند. اگر همان proxy از قبل فعال باشد restart تکراری انجام نمی‌شود؛ `off` نیز daemon مستقیم را بی‌دلیل restart نمی‌کند.

تغییر port، activation و deactivation تراکنشی‌اند: override قبلی پیش از تغییر نگه داشته می‌شود و شکست reload، restart یا verification باعث تلاش برای بازگرداندن همان وضعیت قبلی می‌شود. اگر override دیگری هنوز proxy تنظیم کند، `off` آن را حذف نمی‌کند و وضعیت را صریح گزارش می‌دهد. reboot همه‌ی stateهای زیر `/run` را پاک می‌کند.

نام واقعی command برابر `nix-proxy` است و در Bash/Zsh نیز کار می‌کند؛ `nix_proxy` wrapper اصلی Fish است. `test` یک درخواست کوتاه به cache رسمی Nix می‌فرستد، اما config یا service را تغییر نمی‌دهد.

این ابزار privileged و عمداً imperative است. کاربرد اصلی آن sourceهایی است که cache ندارند یا از شبکه‌ی مستقیم قابل دریافت نیستند؛ proxy همین shell همچنان مسئولیت `proxy_on` یا `px` است.

### `extract` — انتخاب extractor از روی پسوند

```bash
extract backup.tar.zst
extract archive.7z assets.zip
```

فرمت‌های tar، gzip، bzip2، xz، zstd، zip، rar و 7z پوشش داده می‌شوند. برای archive ناشناس هیچ command حدسی اجرا نمی‌شود.

### `mkcd`

```bash
mkcd reports/2026-08
```

directory را می‌سازد و فقط در صورت موفقیت وارد آن می‌شود.

---

# جست‌وجوی فایل و محتوا

## `rg` — جست‌وجوی متن و تولید فهرست فایل

### جست‌وجوی معمولی، شامل hidden ولی نه `.git`

```bash
rg -n --hidden -g '!.git' 'PROXY_(HOST|PORT)'
```

- `-n` شماره خط می‌دهد؛
- `--hidden` dotfileها را می‌بیند؛
- `-g '!.git'` metadata گیت را حذف می‌کند؛
- pattern quote شده تا shell آن را تفسیر نکند.

### فقط فایل‌های Nix، با context

```bash
rg -n -C 2 -g '*.nix' 'mkForce|mkDefault|mkAfter'
```

### استفاده از `rg --files` به‌عنوان producer

```bash
set query 'niri|noctalia'
rg --files | rg --smart-case "$query"
```

`rg --files` محتوای فایل را جست‌وجو نمی‌کند؛ مسیر فایل‌های قابل مشاهده طبق ignore ruleها را می‌دهد. `rg` دوم روی خود pathها فیلتر می‌زند.

### پیدا کردن entry pointهای Nix

```bash
rg --files -g '*.nix' |
  rg '(^|/)(flake|default)\.nix$'
```

### pipeline امن برای نام فایل دارای فاصله

```bash
rg --files -0 -g '*.nix' |
  xargs -0 -r rg -n --color=always 'specialArgs|extraSpecialArgs' |
  fzf --ansi
```

`-0` و `xargs -0` delimiter را NUL می‌کنند؛ newline یا space داخل filename دیگر مرز آرگومان نیست.

### خروجی machine-readable

```bash
rg --json -g '*.nix' 'proxy' |
  jq -r 'select(.type == "match") | [.data.path.text, .data.line_number] | @tsv'
```

این روش برای automation بهتر از parse کردن output رنگی انسان‌محور است.

## `rga` — همان جست‌وجو در PDF، DOCX و archive

```bash
rga -n --hidden --glob '!node_modules' \
  'invoice|رسید|شماره پیگیری' ~/Documents
```

`ripgrep-all` converter مناسب PDF، Office document، SQLite، archive و metadata رسانه را انتخاب می‌کند. وقتی فقط source text داریم، `rg` سریع‌تر و ساده‌تر است.

## `fd` — پیدا کردن path با syntax انسانی

```bash
fd -H -t f -e nix .
fd -t f -e jpg -e png . ~/Pictures
fd -t d '^node_modules$' .
```

- `-H` hiddenها را می‌بیند؛
- `-t f` فقط file؛
- `-e` extension؛
- pattern regex است و path starting point آرگومان بعدی است.

### اجرای command روی نتیجه‌ها

```bash
fd -0 -t f -e json . |
  xargs -0 -r -n1 jq empty
```

برای preview کردن تغییر قبل از اجرا:

```bash
fd -t f -e nix . -x echo alejandra --check '{}'
```

---

# انتخاب تعاملی با FZF

## باز کردن فایل پیدا‌شده در Neovim

```bash
nvim (rg --files | fzf \
  --preview 'bat --color=always --style=numbers --line-range :300 {}')
```

این syntax مخصوص Fish command substitution است. در Bash معادل `nvim "$(...)"` است.

## انتخاب نتیجه‌ی جست‌وجو با preview خط

```bash
rg -n --color=always 'TODO|FIXME|HACK' |
  fzf --ansi --delimiter : \
      --preview 'bat --color=always --highlight-line {2} {1}'
```

`--ansi` رنگ rg را حفظ می‌کند و `{1}`/`{2}` fieldهای filename و line number هستند.

## انتخاب process برای مشاهده، نه kill کورکورانه

```bash
procs --color always |
  fzf --ansi --header 'Select a process to inspect'
```

برای signal دادن ابتدا PID و command را دوباره بررسی کنید؛ fuzzy selection نباید به عملیات destructive مستقیم وصل شود.

---

# مشاهده‌ی فایل، directory و دیسک

## `eza`

```bash
eza -lah --git --group-directories-first
 eza --tree --level=3 --ignore-glob='.git|node_modules|result'
```

ستون Git در `eza -l --git` برای دیدن فایل‌های modified/untracked بدون اجرای status کامل مفید است.

## `bat`

```bash
bat --diff file.nix
bat -n --line-range 120:180 modules/home/cli/fish.nix
```

`bat --diff` تغییر خطوط نسبت به Git index را کنار متن نشان می‌دهد.

## `duf`، `dust` و `nix-du`

```bash
duf
 dust -r -d 3 "$HOME"
nix-du -s /nix/store
```

- `duf`: filesystem و mount capacity؛
- `dust`: مصرف directory به‌شکل tree؛
- `nix-du`: فضای store و میزان آزادشدنی با توجه به referenceها.

هیچ‌کدام به‌تنهایی مجوز حذف نمی‌دهند؛ ابتدا root و generationهای نگه‌دارنده را پیدا کنید.

## فایل باز و port listener

```bash
lsof ~/Downloads/archive.iso
lsof -nP -iTCP -sTCP:LISTEN
```

`-nP` reverse DNS و تبدیل شماره port به service name را خاموش می‌کند؛ خروجی سریع‌تر و دقیق‌تر برای diagnosis است.

---

# تغییر متن و داده‌ی ساخت‌یافته

## `sd` — جایگزینی قابل‌خواندن

```bash
rg -n 'old-name' modules docs
sd 'old-name' 'new-name' modules/example.nix
git diff -- modules/example.nix
```

`sd` فایل را in-place تغییر می‌دهد. اجرای `rg` قبل و `git diff` بعد، محدوده و نتیجه را قابل مشاهده می‌کند.

چند فایل، امن برای فاصله:

```bash
rg -l -0 'old-name' modules |
  xargs -0 -r sd 'old-name' 'new-name'
```

## `jq` — JSON

```bash
# انتخاب fieldها و مرتب‌سازی
jq -r '.[] | select(.enabled) | [.name, .version] | @tsv' packages.json |
  sort -f

# گروه‌بندی و شمارش
jq 'group_by(.status) | map({status: .[0].status, count: length})' results.json

# update بدون overwrite ناامن
jq '.settings.timeout = 30' config.json > config.json.new &&
  jq empty config.json.new &&
  mv config.json.new config.json
```

## `yq` — YAML

```bash
yq '.services | keys' compose.yaml
yq '.jobs.*.runs-on' .github/workflows/*.yml
yq -i '.version = "2"' config.yaml
git diff -- config.yaml
```

## تبدیل output قدیمی به JSON با `jc` و query با `jq`

`jc` داخل `dev cli` است:

```bash
dev cli jc ls -l /etc |
  jq -r '.[] | select(.size > 1048576) | [.filename, .size] | @tsv'
```

این ترکیب از parse کردن columnهای متغیر output متنی قابل اعتمادتر است.

## `dasel` برای چند format

```bash
dev cli dasel -f config.toml '.database.port'
dev cli dasel -f data.xml -r xml '.users.user.[0].name'
```

وقتی یک pipeline باید JSON/YAML/TOML/XML را با interface مشابه بخواند، `dasel` مناسب‌تر از افزودن parser جدا برای هر format است.

---

# HTTP، دانلود و انتقال

## `xh` — API تعاملی و خوانا

```bash
xh GET https://api.example.com/items page==2 limit==50
xh POST https://api.example.com/items name='demo' enabled:=true
xh -A bearer -a "$TOKEN" GET https://api.example.com/private
```

- `key==value` query parameter است؛
- `key=value` JSON string؛
- `key:=value` JSON typed value؛
- token را در command history literal ننویسید.

بررسی فقط header و status:

```bash
xh --headers --follow GET https://example.com
```

## `curl` — انتخاب اول برای دانلود مقاوم و SOCKS5H

برای requestهای کوتاه automation، زمان کل را محدود کنید:

```bash
curl --fail-with-body --location \
  --retry 5 --retry-delay 2 --retry-connrefused \
  --connect-timeout 10 --max-time 120 \
  --output artifact.tar.zst \
  https://example.com/artifact.tar.zst
```

برای فایل حجیم resumable، `--max-time` نگذارید تا یک دانلود سالم و طولانی بی‌دلیل قطع نشود:

```bash
install -d -m 700 ~/Downloads/nix-recovery
curl --fail --show-error --location --continue-at - \
  --retry 8 --retry-delay 2 --retry-connrefused \
  --connect-timeout 30 \
  --output ~/Downloads/nix-recovery/source.part \
  'URL-FROM-THE-ACTUAL-ERROR'
```

همان فایل از SOCKS5H محلی:

```bash
curl --proxy "socks5h://$PROXY_HOST:$PROXY_PORT" \
  --fail --show-error --location --continue-at - \
  --retry 8 --retry-delay 2 --retry-connrefused \
  --connect-timeout 30 \
  --output ~/Downloads/nix-recovery/source.part \
  'URL-FROM-THE-ACTUAL-ERROR'
```

اجرای دوباره‌ی command با همان output از اندازه‌ی فعلی ادامه می‌دهد، به شرط آن‌که server از Range پشتیبانی کند. `--retry-all-errors` عمداً در recipe عمومی فایل قرار نگرفته است: خود curl آن را گزینه‌ای تهاجمی می‌داند و برای output قابل‌ادامه باید براساس failure واقعی اضافه شود.

## `wget`

`wget --continue` دانلود تک‌اتصالی ساده را ادامه می‌دهد:

```bash
wget --continue --tries=8 --timeout=30 \
  --output-document=~/Downloads/nix-recovery/source.part \
  'URL-FROM-THE-ACTUAL-ERROR'
```

GNU Wget پروکسی SOCKS را مستقیم پشتیبانی نمی‌کند؛ برای SOCKS5H، `curl --proxy` انتخاب روشن‌تری از `px wget` است. قابلیت mirror را فقط برای یک domain و پس از بررسی حجم و robots policy به‌کار ببرید:

```bash
wget --mirror --convert-links --adjust-extension \
  --page-requisites --no-parent https://example.com/docs/
```

## `aria2c`

برای فایل بزرگ مستقیم یا mirrorهای واقعاً یکسان، چهار اتصال شروع متعادلی است:

```bash
aria2c --continue=true --auto-file-renaming=false \
  --allow-overwrite=true --max-tries=8 --retry-wait=2 \
  -x 4 -s 4 -k 1M \
  --dir ~/Downloads/nix-recovery --out source.part \
  'URL-FROM-THE-ACTUAL-ERROR'
```

`-x` connectionهای هر server و `-s` تعداد splitهاست. اتصال بیشتر تضمین سرعت بیشتر نیست و می‌تواند server یا proxy محلی را اشباع کند. مستندات رسمی aria2 برای proxyهای HTTP/HTTPS syntax نوع HTTP را تعریف می‌کند و SOCKS5H فعلی ما را تضمین نمی‌کند؛ بنابراین این repository، aria2 را برای direct/multi-source و curl را برای proxy محلی پیشنهاد می‌کند.

## hash دانلود را جداگانه تأیید کنید

Hash مورد انتظار باید از release page، manifest امضاشده یا خطای واقعی Nix بیاید؛ hash محاسبه‌شده از همان download به‌تنهایی اصالت را ثابت نمی‌کند:

```bash
cd ~/Downloads/nix-recovery
expected_sha256='HEX-SHA256-FROM-TRUSTED-SOURCE'
printf '%s  %s\n' "$expected_sha256" source.part |
  sha256sum --check --strict -
```

تا پیش از `OK` فایل را rename، extract یا import نکنید. در fixed-outputهای Nix، برابری candidate و Store path مورد انتظار همان hash، mode و name را با هم کنترل می‌کند؛ راهنمای محدود آن در [قواعد شبکه و recovery](09-rules.md#بازیابی-دستی-یک-fixed-output-حجیم) است.

## `rsync` — همیشه اول dry-run

```bash
rsync -aHAXvn --delete --info=progress2 source/ destination/
rsync -aHAXv  --delete --info=progress2 source/ destination/
```

- slash آخر `source/` یعنی محتوای directory؛
- `-n` preview؛
- `--delete` فایل اضافی مقصد را حذف می‌کند و بدون dry-run خطرناک است.

ارسال remote با partial resume:

```bash
rsync -aHAX --partial --append-verify --info=progress2 \
  ./data/ user@host:/srv/data/
```

## انتقال موقت با Magic Wormhole

داخل `dev cli`:

```bash
dev cli wormhole send report.tar.zst
dev cli wormhole receive
```

کد یک‌بارمصرف را از کانال جداگانه منتقل کنید.

---

# DNS و تشخیص شبکه

DNS سیستم همیشه به DNSCrypt محلی اشاره می‌کند؛ ابزارهای زیر برای پرسش و diagnosis هستند، نه تغییر مالک DNS.

## health check بدون تغییر تنظیمات

```bash
systemctl is-active NetworkManager dnscrypt-proxy
nmcli general status
ip -brief link
ip route
cat /etc/resolv.conf
ss -lntup '( sport = :53 )'

# بار دوم باید معمولاً از cache محلی سریع‌تر باشد
dig +stats @127.0.0.1 example.com A
dig +stats @127.0.0.1 example.com A

# زمان‌های DNS، TCP، TLS و کل request مستقیم
curl --silent --show-error --output /dev/null \
  --write-out 'dns=%{time_namelookup} connect=%{time_connect} tls=%{time_appconnect} total=%{time_total}\n' \
  https://cache.nixos.org/nix-cache-info

nix_proxy status
# فقط وقتی proxy core محلی باید فعال باشد:
nix_proxy test
```

`nix_proxy test` عمداً مسیر proxy را می‌سنجد و در حالت خاموش‌بودن proxy باید failure بدهد؛ curl قبل از آن مسیر مستقیم shell را اندازه می‌گیرد، مگر این‌که `proxy_on` فعال باشد. این خروجی‌ها را قبل و بعد از تغییر BBR، MTU، DNS یا IPv6 مقایسه کنید؛ صرف وجود یک tuning دلیل بهتر بودن آن نیست.

## queryهای دقیق

```bash
dig +short A example.com
dig +short AAAA example.com
dig +trace example.com
doggo example.com A @1.1.1.1
doggo example.com HTTPS --protocol tls --server 1.1.1.1
```

مقایسه resolver محلی و خارجی:

```bash
printf 'local:  '; dig +short @127.0.0.1 example.com A
printf 'quad9:  '; dig +short @9.9.9.9 example.com A
```

## مسیر و packet loss

```bash
mtr --report --report-cycles 20 --show-ips example.com
gping example.com 1.1.1.1
```

packet loss روی hop میانی لزوماً loss انتها نیست؛ routerها ممکن است ICMP را rate-limit کنند. hop نهایی معیار مهم‌تری است.

## port و TLS

```bash
xh --verify=yes GET https://example.com
dev build openssl s_client -connect example.com:443 -servername example.com </dev/null
```

ابزارهای عمیق‌تر داخل `dev net`:

```bash
dev net nmap -sV --reason -Pn example.com
dev net testssl --warnings batch example.com:443
dev net oha -n 200 -c 10 https://example.com/health
```

فقط سامانه‌ای را scan یا load-test کنید که مالک آن هستید یا اجازه دارید.

## throughput کنترل‌شده

```bash
# روی ماشین مقصد مجاز
dev net iperf3 -s

# روی client
dev net iperf3 -c host.example -P 4 -t 20
```

`iperf3` ظرفیت مسیر را اندازه می‌گیرد، نه سرعت application یا CDN عمومی.

---

# Git و بررسی تغییر

## قبل از commit

```bash
git status --short
git diff --check
git diff --stat
git diff --word-diff=color -- docs/04-cli.md
git diff --cached
```

`git diff --check` whitespace error و conflict markerهای واقعی را پیدا می‌کند. همیشه staged diff را جدا از working-tree diff بخوانید.

## جست‌وجوی تاریخچه

```bash
git log --oneline --decorate --graph --all
git log -S'net.ipv4.ip_forward' -- modules/nixos
git log -G'proxy.*port' -p -- modules
```

- `-S` تغییر تعداد یک رشته را پیدا می‌کند؛
- `-G` diffهایی را پیدا می‌کند که خطشان با regex تطبیق دارد.

## مقایسه‌ی ساختاری

`difftastic` در `dev agent` و `dev cli` است:

```bash
dev cli difft --display side-by-side file.old.nix file.new.nix
GIT_EXTERNAL_DIFF=difft dev cli git diff
```

برای استفاده‌ی دائمی از external diff ابتدا رفتار exit code و pager را در repository آزمایشی بررسی کنید.

---

# Process، job و log

ابزارهای سنگین‌تر داخل `dev cli` هستند:

```bash
dev cli procs --tree
dev cli bandwhich
dev cli tailspin /var/log/example.log
dev cli pueue add -- long-running-command
dev cli pueue status
```

`bandwhich` برای دیدن مصرف تقریبی هر process به دسترسی‌های network مناسب نیاز دارد. `pueue` commandهای طولانی را از terminal جاری جدا و صف‌بندی می‌کند؛ جای systemd service دائمی نیست.

---

# پرامپت Starship

پرامپت عمداً کوتاه است، اما context مهم را نشان می‌دهد:

- devShell فعال و نام آن؛
- وضعیت proxy و port؛
- حضور در Box؛
- branch و شمارنده‌های Git؛
- hostname فقط در SSH؛
- exit status command شکست‌خورده.

اگر prompt کند شد:

```bash
starship timings
```

ابتدا module کند را پیدا کنید؛ خاموش‌کردن تصادفی همه‌ی indicatorها diagnosis نیست.

---

# انتخاب ابزار بر اساس سؤال

| سؤال | ابزار اول | ابزار دوم/ترکیب |
| :--- | :--- | :--- |
| متن کجاست؟ | `rg` | `fzf`, `jq --json` |
| filename کجاست؟ | `fd` یا `rg --files` | `fzf` |
| متن داخل PDF/DOCX چیست؟ | `rga` | `fzf` |
| چه چیزی دیسک را پر کرده؟ | `duf`, `dust` | `nix-du`, `nix-tree` |
| چه processای port را گرفته؟ | `lsof -nP -i` | `procs` |
| JSON/YAML چه ساختاری دارد؟ | `jq`, `yq` | `fx`, `jless`, `dasel` |
| API چه برمی‌گرداند؟ | `xh` | `jq` |
| دانلود ناپایدار/پراکسی SOCKS است؟ | `curl --continue-at -` | `wget -c` برای direct |
| فایل مستقیم چنداتصالی است؟ | `aria2c -x 4 -s 4` | `curl` تک‌اتصالی |
| sync چه چیزی را حذف می‌کند؟ | `rsync -n --delete` | سپس اجرای بدون `-n` |
| DNS کجا متفاوت است؟ | `dig`, `doggo` | `mtr`, `testssl` |
| command واقعاً سریع‌تر شد؟ | `hyperfine` | warmup و چند run |
| یک تغییر Nix چرا بزرگ شد؟ | `nix-diff`, `nix-tree` | [فصل ۰۲](02-nix.md) |

---

بعدی: [۰۵ دسکتاپ](05-desktop.md)
