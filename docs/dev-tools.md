# 🛠️ ابزارهای توسعه

## ابزارهای Nix

| ابزار | کاربرد |
|---|---|
| **nixd** | LSP برای ویرایشگر (تکمیل کد Nix) |
| **nix-tree** | نمایش درخت وابستگی‌های Nix store |
| **nvd** | مقایسه دو نسل NixOS |
| **nix-search-tv** | جستجوی تعاملی nixpkgs (TUI) |
| **comma** | اجرای هر دستور بدون نصب (` , command`) |
| **nix-index** | پیدا کردن بسته‌ای که فایل خاصی فراهم می‌کند |
| **nix-output-monitor** | نمودار زیبای پیشرفت build |

### دستورات مفید

```bash
# جستجوی بسته
nix-search-tv                   # جستجوی تعاملی
nix search nixpkgs#firefox      # جستجوی دستی

# مقایسه نسل‌ها
nvd diff /run/current-system /nix/store/...<new>

# اجرا بدون نصب
, cowsay "hello"                # اجرای cowsay بدون نصب

# پیدا کردن بسته از فایل
nix-index                       # ساخت index
nix-locate libssl.so            # جستجو

# نمایش زیبای build
nom build .#nixosConfigurations.nixos.config.system.build.toplevel
```

---

## ابزارهای Git

| ابزار | کاربرد |
|---|---|
| **git** | کنترل نسخه |
| **delta** | نمایش زیبای diff (syntax highlighting) |
| **gh** | GitHub CLI |
| **lazygit** | TUI برای git |

### دستورات Git

```bash
# پایه
git status              # وضعیت (alias: gst)
git add --all           # افزودن همه (alias: gaa)
git commit -m "msg"     # ثبت
git push                # ارسال
git pull --rebase       # دریافت با rebase

# شاخه‌ها
git checkout -b feature # شاخه جدید
git checkout main       # سوییچ
git branch -d feature   # حذف شاخه

# تاریخچه
git log --oneline --graph --decorate  # نمایش زیبا (alias: gl)

# delta (diff زیبا)
git diff                # نمایش با delta
git show                # نمایش آخرین commit
```

---

## ابزارهای ساخت و اجرا

| ابزار | کاربرد |
|---|---|
| **just** | جایگزین مدرن `make` |
| **watchexec** | اجرای خودکار دستور هنگام تغییر فایل |
| **hyperfine** | بنچمارک دستورات |

### مثال justfile

```just
# اجرای پروژه
run:
    cargo run

# تست
test:
    cargo test

# بیلد
build:
    cargo build --release

# همه
all: build test

# دیپلوی
deploy: build
    rsync -avz target/release/app server:/opt/
```

### مثال watchexec

```bash
watchexec -e py python main.py      # اجرا هنگام تغییر .py
watchexec -e rs cargo test           # اجرا هنگام تغییر .rs
watchexec -w src -e ts npm run build # watch فقط src/
```

---

## تحلیل کد

| ابزار | کاربرد |
|---|---|
| **tokei** | شمارش خطوط کد بر اساس زبان |
| **difftastic** | مقایسه هوشمند فایل‌ها (syntax-aware) |

```bash
tokei               # شمارش کل پروژه
tokei --sort lines  # مرتب‌سازی بر اساس تعداد خطوط

difft old.py new.py # مقایسه هوشمند
```

---

## GitHub

| ابزار | کاربرد |
|---|---|
| **gh** | GitHub CLI |
| **gh-dash** | داشبورد TUI |

```bash
gh pr list          # لیست PRها
gh pr create        # ساخت PR
gh pr merge 42      # ادغام PR #42
gh issue create     # ساخت issue
gh repo clone ...   # کلون ریپو

gh-dash             # داشبورد TUI
```
