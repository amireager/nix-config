# ۰۲ — دستورهای Nix که واقعاً به کار می‌آیند

این صفحه آموزش زبان Nix نیست. فهرست دستورهایی است که در این سیستم نصب‌اند و
روزی که چیزی خراب شود یا دیسک پر شود، همان‌هایی‌اند که سراغشان می‌روی.

بعضی‌شان دائمی‌اند (چون وقتی به آن‌ها نیاز داری معمولاً وسط یک مشکلی) و
بعضی داخل `dev nix` هستند.

---

## ساخت سیستم

| مخفف | دستور کامل | چه می‌کند |
| :--- | :--- | :--- |
| `sw` | `nh os switch` | بساز، اعمال کن، برای بوت بعدی هم ثبت کن |
| `tst` | `nh os test` | بساز و اعمال کن، ولی بعد از ریست نباشد |
| `bld` | `nh os build` | فقط بساز، هیچ چیز را عوض نکن |

`tst` برای وقتی است که مطمئن نیستی: اگر سیستم خراب شد، ریست کافی است.

```sh
nh os switch --ask        # اول تفاوت را نشان بده، بعد بپرس
nh os switch -- --show-trace   # وقتی خطا مبهم است
```

`nh` روی `nixos-rebuild` نشسته و دو کار اضافه می‌کند: خروجی خوانا (با
`nix-output-monitor`) و نمایش تفاوت نسل‌ها. اگر خودش خراب شد، راه خام هست:

```sh
nrf     # sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

### به‌روزرسانی

```sh
nix flake update                          # همه ی inputها
nix flake lock --update-input nixpkgs     # فقط یکی
```

بعدش `bld` بزن نه `sw` — اول ببین می‌سازد.

---

## دیسک پر شده

اولین سؤال: چه چیزی جا گرفته؟

```sh
nix-size                  # حجم closure سیستم فعلی + ۲۵ عامل بزرگ
nix-size /nix/store/xxx   # حجم هر مسیر دیگر
nix-du -s /nix/store      # کدام مسیرها واقعاً دیسک می‌خورند
```

`nix-size` خودنوشته است (در `dev nix`) چون فراخوانی مفیدش طولانی است:
`nix path-info -rSh` بعد مرتب‌سازی بعد ۲۵ تای اول.

تفاوت مهم: `nix-du` فضای **واقعاً آزادشدنی** را می‌گوید — یک مسیر ۲ گیگی که
پنج نسل به آن اشاره می‌کنند، با پاک کردن یکی آزاد نمی‌شود.

### پاک کردن

```sh
nh clean all              # با سیاست پیش فرض: ۱۰ روز و ۱۰ نسل
nix store gc              # هرچه ریشه ندارد
nix store optimise        # فایل های یکسان را hard-link کن
```

`nh clean` خودکار هم اجرا می‌شود (`--keep-since 10d --keep 10` در
`core.nix`) و `nix.optimise` هم زمان‌بندی شده.

⚠️ محیط‌هایی که با `dev` وارد شده‌ای پاک **نمی‌شوند** — چون GC root دارند در
`~/.local/share/dev-roots/`. برای آزاد کردنشان باید آن ریشه‌ها را دستی حذف
کنی.

---

## چرا این rebuild شد؟

معمول‌ترین سؤال بعد از یک `nix flake update` که نیم ساعت طول کشیده.

```sh
nix-diff /run/current-system /nix/var/nix/profiles/system-123-link
```

`nix-diff` دقیق می‌گوید کدام derivation عوض شده و چرا — تا سطح یک متغیر
محیطی. `nh` خودش بعد از هر ساخت خلاصه‌ی تفاوت را نشان می‌دهد، پس معمولاً
`nix-diff` را وقتی می‌زنی که آن خلاصه کافی نبوده.

```sh
nix-tree                              # درخت وابستگی، تعاملی
nix why-depends /run/current-system /nix/store/xxx
```

`nix why-depends` جواب «این چیز اصلاً از کجا آمده؟» را می‌دهد — مثلاً چرا
`python2` در closure است.

---

## پیدا کردن چیزها

```sh
nix search nixpkgs ripgrep       # جستجوی پکیج
nix-locate --minimal bin/rg      # کدام پکیج این باینری را دارد
, rg                             # یک بار اجرا کن بدون نصب
```

`nix-locate` و `,` بلافاصله کار می‌کنند چون ایندکس از پیش ساخته از
`nix-index-database` می‌آید.

> ⚠️ این‌ها **فقط** وقتی اجرا می‌شوند که خودت صدایشان بزنی. غلط تایپی در شل
> جستجوی پکیج راه نمی‌اندازد — دلیلش در [۱۰ تصمیم‌ها](10-decisions.md).

```sh
nix repl                         # بعد :lf . برای بارگذاری این flake
nix eval .#nixosConfigurations.nixos.config.networking.hostName
nix flake metadata               # inputها و تاریخشان
nix-melt                         # نمایشگر TUI برای flake.lock
```

`nix repl` بهترین راه برای فهمیدن این است که یک مقدار در کانفیگ **واقعاً** چه
شده، نه اینکه فکر می‌کنی چه شده.

---

## وقتی چیزی نمی‌سازد

```sh
dev nix && nix-check      # statix + deadnix + flake check
```

`nix-check` سه کار پشت سر هم می‌کند: الگوهای غلط، متغیرهای بی‌استفاده، و
ارزیابی خود flake. اولین چیزی که قبل از کامیت باید زد.

```sh
nix flake check --no-build       # فقط ارزیابی، بدون ساخت
nix build .#nixosConfigurations.nixos.config.system.build.toplevel --show-trace
nix log /nix/store/xxx.drv       # لاگ یک build شکست خورده
```

خطاهای Nix معمولاً بلندند و جواب در **اولین** خط است، نه آخری.

---

## ابزارهای کیفیت کد

دائمی، چون روی فایل‌های بیرون این مخزن هم استفاده می‌شوند:

| ابزار | کار |
| :--- | :--- |
| `statix check .` | الگوهای ضدالگو |
| `deadnix .` | تعریف‌های بی‌استفاده |
| `alejandra .` | فرمت‌کننده (همان `nix fmt`) |
| `nixd` | زبان‌سرور — در nvim خودکار وصل است |

---

## ساخت پکیج — `dev nix`

```sh
nix-init                  # از یک URL، اسکلت derivation بساز
nurl <url>                # عبارت fetcher درست را تولید کن
nix-update <attr>         # نسخه و hash را به‌روز کن
nix-prefetch-git <url>    # hash یک ریپو
nixpkgs-review pr 12345   # یک PR نیکس‌پکیجز را محلی بساز و تست کن
nix-fast-build            # ساخت موازی
```

`nurl` وقت زیادی می‌گیرد اگر ندانی هست: به‌جای حدس زدن `fetchFromGitHub` و
پیدا کردن hash، خودش کل عبارت را می‌سازد.

---

## نسل‌ها و برگشت

```sh
nixos-rebuild list-generations
sudo nix-env --profile /nix/var/nix/profiles/system --rollback
```

یا ساده‌تر: موقع بوت، منوی systemd-boot ده نسل آخر را نگه می‌دارد
(`configurationLimit = 10`). یک سیستم خراب همیشه یک ریست فاصله دارد.

---

## پشت شبکه‌ی فیلترشده

```sh
nix_proxy 1819       # دانلودهای nix-daemon از پروکسی
nix_proxy off
```

یک drop-in برای systemd می‌نویسد و تا ریست می‌ماند. این تنها راهی است که
**دانلودهای خود دیمن** (نه دستورهای تو) از پروکسی رد شوند — متغیرهای محیطی
شل روی `nix-daemon` اثر ندارند چون یک سرویس جداست.

جزئیات در [۰۹ باید و نباید](09-rules.md).

---

بعدی: [۰۳ محیط‌های توسعه](03-dev.md)
