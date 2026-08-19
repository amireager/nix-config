# ۰۸ — Box و Audit: اجرا را محدود کن، سپس source را بررسی کن

دو ابزار مسئولیت جدا دارند:

| ابزار | سؤال | زمان |
| :--- | :--- | :--- |
| `box` | این process چه چیزی را می‌تواند ببیند/تغییر دهد؟ | runtime |
| `dev audit` | source، dependency، image یا system چه مشکلی دارد؟ | static/inspection |

Audit جای sandbox را نمی‌گیرد و sandbox سالم‌بودن dependency را ثابت نمی‌کند.

---

# Threat model Box

Box برای این موارد طراحی شده است:

- پنهان‌کردن Home واقعی و credentialها از child process؛
- جلوگیری از نوشتن تصادفی در project جاری؛
- نگه‌داری package/cacheهای نصب‌شده داخل storage هر project؛
- ساخت محیط ephemeral/offline/clean؛
- share صریح حداقل داده‌ی لازم؛
- حفظ shebangهای absolute و PATH محیط فراخواننده.

Box برای این موارد طراحی نشده است:

- دفاع در برابر kernel exploit؛
- جایگزینی VM؛
- جلوگیری قطعی از bypass proxy وقتی network host فعال است؛
- sandbox کردن process والد یا compositor؛
- پنهان‌کردن چیزی که کاربر صریحاً `-s`/`-S` کرده؛
- تبدیل source نامطمئن به source امن.

---

# Home-Swap

Processها path واقعی Home را انتظار دارند:

```text
/home/amir/project/.venv/bin/python
```

تغییر user به `/home/dev` shebang و pathهای absolute را می‌شکند. Box path را ثابت و backing storage را عوض می‌کند:

```text
Host:    /home/amir → Home واقعی
Box:     /home/amir → <project>/.box/home
```

در نتیجه `~/.ssh`, `~/.aws`, config agentهای دیگر و browser profile از دید process وجود ندارند، مگر کاربر آن‌ها را صریح share کند.

Standard mode environment والد را برای compatibility نگه می‌دارد. برای کد نامطمئن `--secure` environment را clear و mountهای broad runtime را محدود می‌کند.

---

# Workspace contract

فراخوانی فعلی هرگز خودکار به `/work` mount نمی‌شود.

| حالت | `/work` |
| :--- | :--- |
| default persistent | `<project>/.box/work` |
| `--ephemeral` | tmpfs |
| `--workdir DIR` | فقط DIR صریح |

این command فقط plan را نشان می‌دهد:

```bash
box --dry-run command
box --dry-run --ephemeral command
box --dry-run --workdir ./project command
```

---

# storage

```text
.box/
├── .gitignore   # همه‌چیز را ignore می‌کند
├── home/
├── work/
├── tmp/
└── <custom>/    # به /<custom> auto-map می‌شود
```

Directory سفارشی داخل `.box` private sandbox storage است، نه host share تصادفی:

```bash
mkdir -p .box/models
box --dry-run command
# .box/models → /models
```

مشاهده:

```bash
box --path
box --status
du -sh .box
```

حذف:

```bash
box --clean
```

`--clean` کل Home، work، tmp، cache و custom storage همین project را پس از confirmation حذف می‌کند.

---

# modeهای اصلی

## standard

```bash
box command args...
```

- Home و work خصوصی persistent؛
- `/tmp` روی `.box/tmp`؛
- network host؛
- environment inherited + defaultهای Box؛
- `/run` و `/var` read-only برای compatibility.

برای installer trusted-ish یا ابزار توسعه‌ای که فقط نباید Home واقعی را ببیند مناسب است.

## secure

```bash
box --secure command
```

- clear environment؛
- `/run` و `/var` عمومی حذف؛
- defaultهای HOME/PATH/XDG دوباره تنظیم؛
- network همچنان host است.

Secure مساوی offline نیست.

## offline

```bash
box --net none command
box --offline command
box --no-net command
```

Network namespace جدا می‌شود. DNS و loopback host service نیز در دسترس نیستند.

## ephemeral

```bash
box --ephemeral command
box --tmp command
```

Home، work و tmp در RAM هستند و بعد از exit از بین می‌روند. هیچ `.box` جدیدی ساخته نمی‌شود، مگر share/workdir صریح side effect خودش را داشته باشد.

## ترکیب سخت‌گیرانه

```bash
box --secure --ephemeral --net none command
```

مناسب اجرای کوتاه source ناشناس که به network یا persistence نیاز ندارد.

---

# Shareها

## read-only پیش‌فرض امن‌تر

```bash
box -s ~/Documents/reference.pdf command
box --share ~/src/project:/source command
```

اگر destination داده نشود، path absolute مشابه داخل Box استفاده می‌شود.

## read-write فقط برای output لازم

```bash
mkdir -p output
box -s ./input:/input -S ./output:/output \
  converter /input/file /output/result
```

برای agent:

```bash
box --secure \
  -s "$PWD:/source" \
  -S "$PWD/generated:/output" \
  python /source/agent.py
```

کل repository را `-S` نکنید اگر فقط یک output directory لازم است.

## source ناموجود

```bash
box -s ./does-not-exist command
```

خطای قطعی است. Share ناموجود silently skip نمی‌شود، چون false sense of isolation/workflow می‌ساخت.

## محدودیت syntax

Share با `SRC:DST` بر اساس colon جدا می‌شود. Path دارای colon نیازمند طراحی دیگری است و نباید حدسی parse شود.

---

# Environment

## پاک‌کردن و بازگرداندن حداقل

```bash
box --clear-env command
box --secure --env MODE=test command
box --secure --env-pass NIX_LD command
```

`--env-pass` فقط نام variable معتبر می‌پذیرد و اگر در host set نباشد خطا می‌دهد.

هرگز کل credential environment را با pattern عمومی pass نکنید. Variable لازم را تک‌به‌تک انتخاب کنید.

## PATH

Box PATH caller را حفظ می‌کند و binهای private sandbox را جلو می‌آورد:

```text
~/.local/bin
~/.npm-global/bin
~/.cargo/bin
caller PATH
```

به همین دلیل:

```bash
dev rust box cargo test
```

همان Cargo/Rust toolchain devShell را داخل Box می‌بیند.

## NixLD

اگر `NIX_LD` و `NIX_LD_LIBRARY_PATH` روی host environment موجود باشند، Box آن‌ها را صریح pass می‌کند تا binary precompiled داخل sandbox بتواند اجرا شود.

---

# Network و proxy

## network host

```bash
box --net host command
```

Default است.

## network none

```bash
box --net none command
```

`--unshare-net` واقعی است و از proxy environment قوی‌تر است.

## proxy environment

```bash
box --proxy command
box --proxy 8080 command
box --net proxy:1819 command
```

Box متغیرهای HTTP/HTTPS/ALL proxy را روی SOCKS5 محلی تنظیم می‌کند. این routing اجباری نیست؛ برنامه‌ای که proxy env را نادیده بگیرد و network host دارد می‌تواند مستقیم وصل شود.

اگر عدم دسترسی مهم است:

```bash
box --net none command
```

نه صرفاً `--proxy`.

Port صریح باید decimal و در بازه 1..65535 باشد.

---

# GPU

```bash
box --gpu command
box --secure --gpu command
```

Deviceهای موجود NVIDIA/DRI اضافه می‌شوند. در secure mode فقط driver directoryهای لازم NixOS از `/run` bind می‌شوند.

Model file را read-only بدهید:

```bash
dev ai box --secure --gpu \
  -s /path/to/models:/models \
  llama-bench -m /models/model.gguf
```

GPU access سطح attack و hardware exposure را افزایش می‌دهد؛ فقط workload نیازمند آن باید `-g` بگیرد.

---

# Resource limit

```bash
box --mem 2G --cpu 150% command
```

Box سعی می‌کند command را در systemd user scope اجرا کند:

```text
MemoryMax=2G
CPUQuota=150%
```

اگر user scope در دسترس نباشد warning می‌دهد و بدون limit اجرا می‌کند؛ isolation filesystem همچنان برقرار است. Plan قبل از اجرا:

```bash
box --dry-run --mem 2G --cpu 150% command
```

---

# Profileها

مسیر:

```text
~/.config/box/profiles/<name>.conf
```

هر خط دقیقاً یک argument است؛ shell code source نمی‌شود.

```text
# ~/.config/box/profiles/review.conf
--secure
--net
none
--mem
2G
--share
/home/amir/reference:/reference
```

استفاده:

```bash
box --profiles
box --profile review --dry-run command
box --profile review command
```

Profile trusted user configuration است. Nested profile ممنوع است تا recursion و precedence مبهم نشود. Optionهای بعد از profile نیز parse می‌شوند و می‌توانند mode را تغییر دهند؛ plan را بخوانید.

---

# Inspect

## مسیرهای user/work

```bash
box --inspect command
```

Strace داخل namespace روی target اجرا می‌شود و pathهای زیر را focus می‌کند:

- `/work`؛
- Home ایزوله؛
- `/tmp`؛
- shareهای صریح؛
- custom `.box/<name>` mountها.

## همه‌ی file syscallها

```bash
box --inspect-all command 2>trace.log
```

Output می‌تواند path و داده‌ی حساس محیط sandbox را نشان دهد؛ قبل از انتشار redact کنید.

Inspect behavior را محدود نمی‌کند؛ مشاهده می‌کند. برای enforcement همچنان mount/network/environment mode مهم‌اند.

---

# Recipeهای کامل

## installer با persistence خصوصی

```bash
box --secure --dry-run bash installer.sh
box --secure bash installer.sh
box --status
```

## installer یک‌بارمصرف offline

```bash
box --secure --ephemeral --net none bash installer.sh
```

## build source read-only با output محدود

```bash
mkdir -p output
box --secure --net none \
  -s "$PWD:/source" \
  -S "$PWD/output:/output" \
  bash -lc 'cp -r /source /tmp/project && cd /tmp/project && make && cp app /output/'
```

Source original قابل نوشتن نیست؛ build روی copy tmp انجام می‌شود.

## devShell داخل Box

```bash
dev python box --secure -s "$PWD:/source" \
  python -m compileall -q /source

dev web box --net none -s "$PWD:/source" \
  bash -lc 'cd /source && pnpm test'
```

اگر test نیاز به نوشتن داخل project دارد، source read-only شکست می‌خورد—این failure مفید است و باید output/cache مورد نیاز را جداگانه share کرد.

---

# Audit repository

```bash
dev audit audit-repo .
```

مراحل:

1. Gitleaks روی working tree و Git history؛
2. یافتن recursive lockfileهای شناخته‌شده؛
3. OSV Scanner روی source tree در صورت وجود lockfile؛
4. status غیرصفر اگر finding یا scanner failure باشد.

Lockfileهای شناخته‌شده شامل Flake، Cargo، npm/pnpm، Poetry/uv، Go و requirements است.

## Secret finding

اگر secret واقعی است:

1. revoke/rotate؛
2. exposure scope را پیدا کنید؛
3. current source را پاک کنید؛
4. درباره‌ی history rewrite تصمیم بگیرید؛
5. scanner را دوباره اجرا کنید.

فقط حذف فایل فعلی secret تاریخی را بی‌اعتبار نمی‌کند.

---

# Supply chain و SBOM

```bash
dev audit syft dir:. -o cyclonedx-json > sbom.json
dev audit grype sbom:sbom.json
dev audit trivy fs .
dev audit trivy config .
```

- Syft inventory می‌سازد؛
- Grype vulnerability را روی SBOM بررسی می‌کند؛
- Trivy filesystem/IaC/image را پوشش می‌دهد.

Scanner report نیازمند triage است:

```text
package واقعاً در runtime هست؟
version detection درست است؟
CVE به feature فعال مربوط است؟
fix version وجود دارد؟
false positive یا vendored copy است؟
```

---

# Audit system

```bash
dev audit audit-system
```

- Vulnix closure سیستم جاری را با vulnerability data مقایسه می‌کند؛
- declarationهای `permittedInsecurePackages` را در config پیدا می‌کند؛
- finding و failure status واقعی می‌دهند.

Hardening عمیق:

```bash
dev audit lynis audit system
```

Lynis recommendation عمومی است. هر پیشنهاد را با NixOS module، threat model لپ‌تاپ و workflow واقعی تطبیق دهید؛ score بالاتر به‌تنهایی هدف نیست.

---

# Container image

```bash
dev audit trivy image image:tag
dev audit dive image:tag
dev audit syft image:tag -o table
dev audit cosign verify image:tag
```

Tag mutable است؛ برای deployment قابل اعتماد digest را ثبت و signature policy را مشخص کنید.

---

# checklist اجرای ناشناس

```text
[ ] source را با audit و review بررسی کرده‌ام؟
[ ] آیا network واقعاً لازم است؟
[ ] آیا secure و ephemeral مناسب‌اند؟
[ ] آیا read-only share کافی است؟
[ ] output writable را به کوچک‌ترین directory محدود کرده‌ام؟
[ ] credential environment را pass نکرده‌ام؟
[ ] GPU/rootful/container privilege لازم است؟
[ ] ابتدا --dry-run را خوانده‌ام؟
[ ] بعد از اجرا box --status را بررسی کرده‌ام؟
```

---

بعدی: [۰۹ قواعد عملیاتی](09-rules.md)
