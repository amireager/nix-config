# ۰۱ — نمای کلی معماری و مالکیت

این فصل نقشه‌ی repository است: چه چیزی ورودی است، هر module مالک چه مسئولیتی است، state از کجا عبور می‌کند و برای تغییر یک رفتار باید کدام فایل را باز کرد.

---

# جریان از Flake تا سیستم فعال

```text
flake.nix
│
├── inputs
│   ├── nixpkgs
│   ├── home-manager
│   ├── niri
│   ├── noctalia
│   ├── zen-browser
│   └── nix-index-database
│
├── lib.mkHost
│   └── nixosConfigurations.nixos
│       ├── hosts/nixos
│       │   ├── hardware.nix
│       │   ├── bootloader
│       │   └── modules/nixos/*
│       ├── users/amir/default.nix
│       └── home-manager.nixosModules.home-manager
│           └── users/amir/home.nix
│               └── modules/home/*
│
└── devShells.x86_64-linux
    └── shells/default.nix
        ├── shells/registry.nix
        ├── lib.mkDevShell
        └── shells/<name>
```

یک `nh os switch` NixOS و Home Manager را در یک generation می‌سازد. Home Manager در این repository command جداگانه‌ی deployment نیست.

---

# `flake.nix`

## Inputها

| input | نقش | سیاست version |
| :--- | :--- | :--- |
| `nixpkgs` | packageها و NixOS modules | `nixos-unstable` در lock file |
| `home-manager` | user environment | nixpkgs اصلی را follow می‌کند |
| `niri` | compositor package/module | nixpkgs اصلی را follow می‌کند |
| `noctalia` | shell و Home Manager module | nixpkgs اصلی را follow می‌کند |
| `zen-browser` | browser package | nixpkgs اصلی را follow می‌کند |
| `nix-index-database` | index آماده‌ی file→package | nixpkgs اصلی را follow می‌کند |

`follows = "nixpkgs"` از ورود package setهای موازی جلوگیری می‌کند. `flake.lock` revision دقیق هر dependency را ثبت می‌کند.

## Outputها

```text
nixosConfigurations.nixos

devShells.x86_64-linux.{agent,ai,audit,build,cli,go,media,net,nix,python,rust,web}
formatter.x86_64-linux
```

Aliasهای devShell نیز از Registry ساخته می‌شوند. محیط‌های توسعه بخشی از system closure نیستند مگر کاربر آن‌ها را realise و root کند.

## دو package set

- NixOS package set برای system و Home Manager؛
- package set standalone برای devShellها.

هر دو `allowUnfree = true` دارند، چون NVIDIA/AI و بعضی برنامه‌های desktop به packageهای unfree نیاز دارند.

---

# `lib/` — قراردادهای مشترک

## `mkHost`

ورودی اصلی:

```nix
lib.mkHost {
  hostname = "nixos";
  hostModules = [ ./hosts/nixos ];
  users.amir = ./users/amir;
}
```

کارهایی که انجام می‌دهد:

1. `nixpkgs.hostPlatform` و hostname؛
2. import host moduleها؛
3. import system-side هر user؛
4. نصب Home Manager به‌عنوان NixOS module؛
5. import home-side هر user؛
6. اشتراک package set سیستم با Home Manager؛
7. اضافه‌کردن nix-index-database به shared moduleها؛
8. عبور `inputs`, `hostname`, `flakePath` و `proxy` به مصرف‌کننده‌های لازم.

## `mkDevShell`

Shell module فقط داده‌ی اختصاصی خود را می‌دهد:

```nix
mkDevShell {
  name = "example";
  icon = "🚀";
  description = "...";
  packages = [ ... ];
  env = { ... };
  tips = [ ... ];
  extraHook = ''...'';
}
```

Builder مشترک این‌ها را اضافه می‌کند:

- `DEVSHELL_ACTIVE` و `DEVSHELL_NAME`؛
- banner سازگار با non-interactive execution؛
- metadata derivation؛
- validation نام‌های reserved؛
- hook مشترک.

## `proxy`

Host و port پروکسی محلی در `lib/default.nix` تعریف می‌شوند و به network، Fish، Box و session environment می‌رسند. تغییر این مقدار باید تمام مصرف‌کننده‌ها را هماهنگ نگه دارد.

---

# `hosts/` — چیزهایی که متعلق به یک ماشین‌اند

```text
hosts/nixos/
├── default.nix
└── hardware.nix
```

`hardware.nix` output اولیه‌ی `nixos-generate-config` است و filesystem/deviceها را می‌شناسد. `default.nix` bootloader و profileهای مورد استفاده را انتخاب می‌کند.

Profileهای فعال روی این host:

- core system؛
- network و DNS؛
- security؛
- desktop؛
- laptop power؛
- NVIDIA hybrid graphics؛
- keyd.

چیزهایی که نباید به host دیگر کپی شوند:

- filesystem UUID؛
- NVIDIA bus ID؛
- bootloader assumption؛
- laptop lid/battery policy؛
- hardware-specific kernel module؛
- stateVersion بدون بررسی نصب اولیه.

---

# `users/` — اتصال NixOS user به Home Manager

```text
users/amir/
├── default.nix
└── home.nix
```

## `default.nix`

NixOS باید بداند:

- user عادی است؛
- primary group چیست؛
- supplementary groupها چیستند؛
- login shell چیست.

عضویت `podman` عمدی و privileged است، چون rootful access استفاده می‌شود. این عضویت صرفاً برای rootless container لازم نیست.

## `home.nix`

Home Manager باید بداند:

- username و home directory؛
- Home Manager stateVersion؛
- کدام CLI/dev/GUI/theme moduleها برای این user فعال‌اند.

Explicit import list باعث می‌شود قابلیت‌های user با نگاه به یک فایل دیده شوند. اگر user دوم با profile تقریباً یکسان اضافه شود، آن زمان bundle مشترک ارزش پیدا می‌کند؛ زودتر از آن abstraction اضافه است.

---

# NixOS moduleها

| فایل | مالکیت |
| :--- | :--- |
| `core.nix` | Nix/store، kernel/memory، firmware، locale، fonts، base tools، compatibility و Podman |
| `network.nix` | NetworkManager، DNSCrypt، resolv.conf، proxychains، network tuning و vnStat |
| `security.nix` | firewall، sudo-rs، AppArmor، USBGuard، fwupd و security sysctl |
| `desktop.nix` | Niri، SDDM، PipeWire، Bluetooth، portal و Thunar |
| `keyd.nix` | remap سطح evdev برای Caps tap/hold |
| `hardware/laptop.nix` | logind lid/power، auto-cpufreq، UPower و SMART |
| `hardware/nvidia.nix` | proprietary driver، modesetting، Prime offload و power management |

`core.nix` در وضعیت فعلی گسترده است و بعداً بر اساس مسئولیت به moduleهای کوچک‌تر تقسیم می‌شود؛ network/security/desktop مرز جدا دارند و نباید دوباره در core ادغام شوند.

---

# Home Manager moduleها

## CLI

```text
modules/home/cli/
├── fish.nix
├── starship.nix
├── direnv.nix
├── git.nix
├── tmux.nix
├── zellij.nix
└── tools.nix
```

- Fish مالک abbreviation، alias، function و interactive theme است؛
- `tools.nix` ابزارهای دائمی را نگه می‌دارد؛
- Git/tmux/Zellij config مستقل دارند؛
- direnv project environment را به shell و Neovim متصل می‌کند.

## Development

```text
modules/home/dev/
├── nvim/
├── nix-tools.nix
├── dev-launcher.nix
└── box/
```

- Neovim editor package، pluginها، runtime toolها و Lua config؛
- Nix tools ابزارهایی که هنگام خرابی باید global باشند؛
- `dev` رابط shellها و rootها؛
- Box sandbox global و مستقل از shell.

## GUI

```text
modules/home/gui/
├── niri/
├── browser.nix
├── media.nix
├── terminal.nix
├── wayland.nix
└── xdg.nix
```

NixOS session/serviceها را فراهم می‌کند؛ Home Manager رفتار و ابزار user را.

## Theme

- GTK theme/icon/cursor؛
- Noctalia shell configuration؛
- idle timing خارج از Nix و تحت کنترل GUI/Caffeine.

---

# جریان Desktop

```text
SDDM
└── Niri
    ├── Home Manager config.kdl
    ├── xwayland-satellite
    ├── XDG portals
    └── Noctalia user service
        ├── bar + dock
        ├── launcher + control centre
        ├── notification daemon
        ├── wallpaper + lock
        └── Polkit agent
```

Niri keybindingها commandهای IPC Noctalia را صدا می‌زنند. Swaylock fallback مستقل باقی مانده است.

---

# جریان DNS و Proxy

```text
application
├── direct
├── proxy_on → shell environment
├── px → proxychains برای یک command
├── box --proxy → environment داخل sandbox
└── nix_proxy → drop-in موقت nix-daemon

DNS query
└── /etc/resolv.conf → 127.0.0.1:53
    └── dnscrypt-proxy
        ├── resolverهای DNSSEC/no-log/no-filter
        └── bootstrap/fallback داخلی
```

NetworkManager و resolved مالک DNS نیستند. این یک تصمیم عملیاتی ثبت‌شده است، نه default اتفاقی.

---

# جریان DevShell

```text
shells/registry.nix
├── نام‌ها
├── گروه‌ها
└── aliasها

shells/default.nix
└── import shell module
    └── mkDevShell
        └── devShell derivation + metadata

Home Manager
└── dev command
    ├── menu/completion
    ├── nix develop
    ├── profile
    └── indirect GC-root
```

Registry source نام و ترتیب است؛ shell file محتوا و metadata محیط را تعریف می‌کند. Menu سریع source را می‌خواند و Flake را evaluate نمی‌کند.

---

# مقیاس فعلی و مرز رشد

| امروز | در صورت رشد |
| :--- | :--- |
| یک host x86_64 | برای معماری دوم، per-system output و gate کردن CUDA/NVIDIA لازم است |
| یک user | برای user دوم مشابه، Home profile bundle ارزش پیدا می‌کند |
| ۱۲ shell | Registry assertion و metadata contract مهم‌تر می‌شود |
| یک desktop | desktop profile می‌تواند مستقل از host شود |
| personal modules | export عمومی module فقط وقتی reuse خارجی هدف واقعی باشد |

Frameworkهایی مانند flake-parts صرفاً برای کوتاه‌کردن `flake.nix` فعلی لازم نیستند.

---

# کجا چه چیزی را تغییر دهم؟

| تغییر | فایل مالک |
| :--- | :--- |
| input یا output Flake | `flake.nix` |
| host/hardware/boot | `hosts/<name>` |
| user/group/login shell | `users/<name>/default.nix` |
| انتخاب Home module | `users/<name>/home.nix` |
| Nix/cache/kernel/base | `modules/nixos/core.nix` |
| DNS/proxychains/network | `modules/nixos/network.nix` |
| firewall/sudo/USB | `modules/nixos/security.nix` |
| Niri system session | `modules/nixos/desktop.nix` |
| Niri key/window rule | `modules/home/gui/niri/config.kdl` |
| Noctalia base | `modules/home/theme/noctalia.nix` |
| Fish function/abbr | `modules/home/cli/fish.nix` |
| ابزار دائمی CLI | `modules/home/cli/tools.nix` |
| Neovim plugin/binary | `modules/home/dev/nvim/default.nix` |
| Neovim behavior/key | `modules/home/dev/nvim/lua/*.lua` |
| `dev` behavior/root | `modules/home/dev/dev-launcher.nix` |
| Box runtime | `modules/home/dev/box/box.sh` |
| devShell package | `shells/<name>` |
| shell name/group/alias | `shells/registry.nix` |
| دلیل تصمیم | `docs/10-decisions.md` |

---

بعدی: [۰۲ عملیات Nix](02-nix.md)
