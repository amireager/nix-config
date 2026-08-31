# ۰۲ — عملیات Nix: ساخت، تحلیل، پاک‌سازی و بازگشت

این فصل commandهای Nix را بر اساس ریسک و سؤال عملی مرتب می‌کند. هدف حفظ یک workflow قابل بازگشت است، نه حفظ‌کردن تعداد زیادی flag.

مسیر پایدار Flake روی سیستم نصب‌شده `/etc/nixos` است. این مسیر symlink به checkout واقعی Git است:

```bash
readlink -f /etc/nixos
git -C /etc/nixos status --short
```

در نتیجه `nh`، recovery commandها و helperها مستقل از محل واقعی checkout یک entry point مشترک دارند.

---

# چهار سطح عملیات

| سطح | نمونه | اثر |
| :--- | :--- | :--- |
| Source inspection | `git diff`, `statix`, `deadnix` | فقط فایل‌ها را می‌خواند |
| Evaluation | `nix flake show`, `nix eval` | expression را ارزیابی می‌کند؛ build ندارد |
| Build | `nh os build` | derivationها را می‌سازد؛ سیستم جاری را عوض نمی‌کند |
| Activation | `nh os test/switch` | generation جدید را روی سیستم واقعی فعال می‌کند |

CI این repository تا سطح Evaluation را اجرا می‌کند (`nix flake check` کامل). Build و activation همچنان تصمیم صریح کاربر روی ماشین هدف‌اند.

---

# بررسی policy سرعت Nix

بدون build می‌توان setting مؤثر daemon را دید:

```bash
nix config show |
  rg '^(max-jobs|cores|http-connections|connect-timeout|download-attempts|fallback|auto-optimise-store|use-sqlite-wal|tarball-ttl) ='

systemctl show nix-daemon --property=ActiveState,Environment
systemctl list-timers nix-optimise.timer --no-pager
```

روی host فعلی، `max-jobs=3` و `cores=4` سقف دوازده thread را بین سه derivation تقسیم می‌کند. Transfer settingهای عمومی روی default نگه‌داری‌شده‌ی Nix می‌مانند؛ retry خاص شبکه فقط هنگام استفاده‌ی صریح از ابزار موقت اعمال می‌شود. `fallback=false` فقط source build پس از شکست substitute شناخته‌شده را متوقف می‌کند و مانع build عادی در cache miss نیست.

`auto-optimise-store` خاموش است تا importهای روزمره برای hash/hardlink متوقف نشوند. `nix-optimise.timer` هفته‌ای یک‌بار، روی برق AC و با اولویت CPU/I/O برابر idle اجرا می‌شود.

---

# workflow امن تغییر سیستم

## ۱. Source را بخوان

```bash
cd /etc/nixos
git status --short
git diff --check
git diff --stat
git diff
```

## ۲. بررسی source-only

```bash
dev nix
nix-check
```

`nix-check` در این repository چهار بررسی انجام می‌دهد:

1. parse کردن مستقل تمام فایل‌های `.nix`؛
2. `statix check`؛
3. `deadnix --fail`؛
4. `alejandra --check`.

این command عمداً `nix flake check`، build، network fetch یا activation انجام نمی‌دهد.

## ۳. فقط build

```bash
nrb
# معادل
nh os build ~/nix-config --hostname laptop
```

اگر تغییر بزرگ است:

```bash
nh os build --ask
```

`--ask` قبل از عملیات نهایی تفاوت generation را نشان می‌دهد. build موفق هنوز اثبات نمی‌کند login manager، GPU، suspend یا network runtime درست‌اند.

## ۴. test موقت

```bash
nrt
# معادل
nh os test ~/nix-config --hostname laptop
```

`test` generation را فعال می‌کند ولی آن را default boot نمی‌کند. برای desktop، driver، network و service change مناسب‌تر از switch مستقیم است.

## ۵. switch پایدار

```bash
nrs
# معادل
nh os switch ~/nix-config --hostname laptop
```

راه recovery بدون `nh`:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#laptop
```

---

# Flake و inputها

## دیدن pinها بدون خواندن JSON خام

```bash
nix flake metadata /etc/nixos
nix flake metadata /etc/nixos --json |
  jq -r '.locks.nodes | to_entries[] | [.key, (.value.locked.rev // "-")] | @tsv'
```

## دیدن outputها

```bash
nix flake show /etc/nixos
```

این command evaluation انجام می‌دهد، اما package را build نمی‌کند.

## به‌روزرسانی کنترل‌شده

قبل از update:

```bash
git status --short
git diff -- flake.lock
```

یک input:

```bash
nix flake update nixpkgs
```

همه‌ی inputها:

```bash
nix flake update
```

بعد از update:

```bash
git diff --stat -- flake.lock
git diff -- flake.lock
nrb
```

Update قفل و تغییر configuration را در یک commit مخلوط نکنید، مگر وابستگی مستقیم داشته باشند. یک lock update مستقل rollback و diagnosis را آسان‌تر می‌کند.

## چرا `follows` مهم است؟

Home Manager، Niri، Noctalia، Zen Browser و nix-index-database به nixpkgs اصلی follow می‌کنند. بدون آن ممکن است چند nixpkgs متفاوت وارد graph شوند و package ABI، evaluation و closure را پیچیده کنند.

---

# فهمیدن چیزی که قرار است عوض شود

## generationها

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## تفاوت closure دو generation

```bash
nix store diff-closures \
  /nix/var/nix/profiles/system-42-link \
  /nix/var/nix/profiles/system-43-link
```

برای current و result حاصل از build:

```bash
nix store diff-closures /run/current-system ./result
```

## چرا یک dependency وجود دارد؟

```bash
nix why-depends /run/current-system /nix/store/<hash>-package
```

ابتدا path دقیق را پیدا کنید:

```bash
nix path-info -r /run/current-system | rg '/[^/]*-ffmpeg-'
```

سپس همان path را به `nix why-depends` بدهید. این command مسیر dependency را نشان می‌دهد؛ package را حذف نمی‌کند.

## درخت تعاملی dependency

```bash
nix-tree /run/current-system
```

کلیدهای خود TUI را از help همان برنامه ببینید. کاربرد اصلی: یافتن package کوچکی که یک closure بسیار بزرگ را وارد کرده است.

## فرق derivationها

```bash
nix-diff /run/current-system ./result
```

`nix-diff` برای سؤال «چرا rebuild شد؟» مناسب است؛ `diff-closures` برای سؤال «چه packageهایی اضافه یا حذف شدند؟».

---

# اندازه‌ی closure و مصرف واقعی دیسک

## اندازه‌ی closure

```bash
nix path-info -Sh /run/current-system
nix path-info -rSh /run/current-system |
  sort -k2 -hr |
  head -25
```

helper داخل `dev nix`:

```bash
dev nix nix-size
dev nix nix-size /nix/store/<path>
```

Closure size اندازه‌ی logical تمام dependencyهاست. دو closure ممکن است store pathهای مشترک داشته باشند؛ جمع اعداد آن‌ها برابر فضای فیزیکی مصرف‌شده نیست.

## فضای آزادشدنی

```bash
nix-du -s /nix/store
```

یک store path بزرگ که چند root به آن اشاره می‌کنند با حذف یک generation آزاد نمی‌شود. `nix-du` referenceها را در نظر می‌گیرد و برای تصمیم cleanup مناسب‌تر است.

## چه چیزی package را زنده نگه داشته؟

```bash
nix-store --query --roots /nix/store/<path>
nix-store --gc --print-roots | rg 'dev-roots|profiles|current-system'
```

Root را بدون شناخت حذف نکنید. system generation، user profile، dev root یا result symlink ممکن است مالک آن باشد.

---

# GC-rootهای محیط‌های توسعه

```bash
dev --roots
dev --keep rust
dev --unkeep rust
dev --prune
```

هر environment نگه‌داری‌شده root صریح زیر مسیر زیر دارد:

```text
~/.local/share/dev-roots/<name>/gc-root
```

بررسی مستقل daemon:

```bash
nix-store --gc --print-roots | rg "$HOME/.local/share/dev-roots"
```

منوی سریع `dev` وضعیت روزمره را از symlink محلی می‌خواند و daemon-wide query انجام نمی‌دهد. ثبت indirect root هنگام ورود synchronous است و در صورت failure ورود متوقف می‌شود. برای audit مستقل registry daemon از command بالا استفاده کنید.

---

# پاک‌سازی با ترتیب درست

## ابتدا ببین

```bash
dev --roots
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
nix-du -s /nix/store
```

## سپس generationهای قدیمی

```bash
nh clean all --keep 10 --keep-since 10d
```

همین policy در configuration نیز برای cleanup خودکار `nh` ثبت شده است.

در فشار شدید دیسک می‌توان موقتاً تعداد کمتری نگه داشت، اما قبل از حذف generation سالمی که برای rollback لازم است تصمیم بگیرید.

## garbage collection خام

```bash
nix-collect-garbage -d
```

`-d` generationهای قدیمی profileها را نیز حذف می‌کند. این command recovery history را کم می‌کند و نباید اولین قدم باشد.

## optimize با GC فرق دارد

```bash
nix store optimise
```

Optimize فایل‌های یکسان store را hard-link می‌کند؛ package یا generation حذف نمی‌کند. در این سیستم optimize به‌صورت هفتگی هم فعال است.

---

# Rollback و recovery

## بازگشت از سیستم فعال

```bash
nh os switch --rollback
```

## اگر desktop بالا نیامد

1. reboot؛
2. در systemd-boot generation قبلی را انتخاب کنید؛
3. وارد TTY شوید؛
4. diff آخرین commit را بررسی کنید؛
5. generation سالم را switch کنید یا commit مشکل‌دار را revert کنید.

## Revert بهتر از پاک‌کردن دستی source است

```bash
git log --oneline -10
git revert <bad-commit>
nrb
nrt
```

Revert تاریخچه و دلیل تغییر را حفظ می‌کند. `git reset --hard` برای repository عمومی و patch series معمولاً انتخاب مناسبی نیست.

---

# ابزارهای دائمی Nix

این‌ها بیرون از devShell نصب‌اند چون هنگام خرابی باید فوراً در دسترس باشند:

| ابزار | سؤال |
| :--- | :--- |
| `nix-tree` | چه dependencyهایی در closure هستند؟ |
| `nix-diff` | چرا دو derivation فرق دارند؟ |
| `nix-du` | چه چیزی واقعاً فضای store را نگه داشته؟ |
| `nix-melt` | lock file چه graphی دارد؟ |
| `nix-output-monitor` | build در کدام مرحله است؟ |
| `statix` | anti-patternهای Nix کجاست؟ |
| `deadnix` | binding بلااستفاده کجاست؟ |
| `alejandra` | format canonical repository چیست؟ |
| `nixd` | LSP فایل‌های Nix چگونه فراهم می‌شود؟ |
| `nix-locate` | کدام package یک binary/file را دارد؟ |
| `,` | چگونه package را یک‌بار بدون نصب اجرا کنم؟ |

نمونه:

```bash
nix-locate --minimal --whole-name bin/rg
, cowsay hello
```

`,` environment موقت می‌سازد؛ package را به configuration اضافه نمی‌کند.

---

# `dev nix` برای packaging و review

```bash
dev nix
```

| ابزار | کاربرد |
| :--- | :--- |
| `nurl` | تولید fetcher expression از URL |
| `nix-init` | ساخت scaffold پکیج |
| `nix-update` | update نسخه و hash |
| `nix-prefetch` / `nix-prefetch-git` | محاسبه hash source |
| `nixpkgs-review` | بررسی PR nixpkgs |
| `nix-fast-build` | build موازی outputها |
| `nix-search-tv` | جست‌وجوی تعاملی package |
| `nix-check` | parser + Statix + Deadnix + Alejandra، بدون Flake evaluation |
| `nix-size` | closure size و بزرگ‌ترین contributorها |

Recipe ساخت package جدید:

```bash
mkdir -p /tmp/package-review && cd /tmp/package-review
dev nix
nix-init https://github.com/owner/project
alejandra package.nix
statix check package.nix
```

هیچ expression تولیدشده‌ای را بدون خواندن license، source، install phase و dependencyها وارد system configuration نکنید.

---

# checklist قبل و بعد از تغییر بزرگ

```text
قبل:
[ ] working tree را می‌شناسم
[ ] generation سالم برای rollback دارم
[ ] rootهای dev مهم ثبت‌اند
[ ] تغییر hardware/network را مستقیم switch نمی‌کنم

بعد:
[ ] source checks پاس شده
[ ] build موفق بوده
[ ] diff closure خوانده شده
[ ] test روی desktop/network/suspend انجام شده
[ ] فقط سپس switch و commit نهایی انجام شده
```

---

بعدی: [۰۳ محیط‌های توسعه](03-dev.md)
