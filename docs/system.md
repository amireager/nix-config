# 🖥️ سیستم — ساختار کلی و سخت‌افزار

## سخت‌افزار

| مشخصه | مقدار |
|---|---|
| پردازنده | AMD (با KVM) |
| کارت گرافیک | AMD iGPU + Nvidia dGPU (hybrid offload) |
| صفحه‌نمایش | eDP-1 — 1920×1080@60Hz |
| فایل‌سیستم | ext4 (root) + vfat (boot) |
| حافظه swap | فیزیکی + ZRAM (25% RAM) |
| بوت‌لودر | systemd-boot (UEFI) |

## هسته NixOS

| تنظیم | مقدار | توضیح |
|---|---|---|
| کانال | `nixos-unstable` | آخرین بسته‌ها (rolling release) |
| کرنل | `linuxPackages_latest` | آخرین کرنل پایدار |
| Flakes | فعال | `nix-command` + `flakes` |
| بهینه‌سازی فروشگاه | `auto-optimise-store` | حذف فایل‌های تکراری در Nix store |
| ZRAM | 25% RAM | حافظه فشرده در RAM |
| swappiness | 20 | ترجیح RAM نسبت به swap |
| vfs_cache_pressure | 50 | نگهداری بیشتر metadata فایل‌سیستم |

## زبان و منطقه

| تنظیم | مقدار |
|---|---|
| منطقه زمانی | `Asia/Tehran` |
| زبان پیش‌فرض | `en_US.UTF-8` |
| صفحه‌کلید | `us,ir` |
| سوییچ زبان | `Alt+Shift` |

## فونت‌ها

| فونت | کاربرد |
|---|---|
| **Vazirmatn** | فونت فارسی (سیستم و رابط کاربری) |
| **JetBrains Mono NF** | فونت برنامه‌نویسی با آیکون‌ها |
| **Fira Code NF** | فونت برنامه‌نویسی با ligatures |

## مدیریت سیستم (NH)

ابزار `nh` جایگزین مدرن `nixos-rebuild` هست.

```bash
# بازسازی سیستم
nh os switch

# تست بدون اعمال
nh os test

# فقط بیلد (بدون سوییچ)
nh os build

# بازسازی Home Manager
nh home switch

# پاکسازی نسل‌های قدیمی (خودکار — هر 30 روز، نگهداری 5 نسل)
nh clean
```

## متغیرهای محیطی Wayland

این متغیرها به صورت سیستمی تنظیم شده‌اند:

| متغیر | مقدار | توضیح |
|---|---|---|
| `QT_QPA_PLATFORM` | `wayland` | اپلیکیشن‌های Qt از Wayland استفاده کنند |
| `NIXOS_OZONE_WL` | `1` | اپلیکیشن‌های Electron (VS Code, ...) از Wayland |
| `AVALONIA_PLATFORM` | `Wayland` | اپلیکیشن‌های Avalonia |

## AppImage

پشتیبانی از AppImage فعال هست (binfmt + fuse). فایل‌های `.AppImage` مستقیم اجرا می‌شوند:

```bash
chmod +x app.AppImage
./app.AppImage
```

## ساختار فایل‌های پیکربندی

```
nix-config/
├── flake.nix              ← نقطه ورود اصلی
├── flake.lock             ← قفل نسخه‌ها (عدم تغییر دستی)
├── lib/
│   ├── default.nix
│   └── mkHost.nix         ← تابع ساخت هاست
├── hosts/nixos/
│   ├── default.nix         ← تنظیمات هاست (بوت، سخت‌افزار)
│   └── hardware.nix        ← شناسایی خودکار سخت‌افزار
├── modules/
│   ├── nixos/              ← تنظیمات سطح سیستم
│   └── home/               ← تنظیمات سطح کاربر (Home Manager)
└── users/amir/
    └── default.nix          ← پروفایل کاربر
```
