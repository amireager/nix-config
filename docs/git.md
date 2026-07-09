# 🔀 Git — مدیریت نسخه

## Git

مدیریت نسخه توزیع‌شده.

### alias‌های تعریف‌شده

```bash
git st              # git status -sb (خلاصه)
git lg              # git log --oneline --graph --decorate --all
git last            # git log -1 HEAD --stat
git unstage         # git reset HEAD --
git amend           # git commit --amend --no-edit
```

### abbreviations (fish)

```bash
gs                  # git status
ga                  # git add
gc "message"        # git commit -m "message"
gco branch          # git checkout branch
gcb new-branch      # git checkout -b new-branch
gp                  # git push
gpl                 # git pull --rebase
gaa                 # git add --all
gl                  # git log --oneline --graph --decorate
```

### تنظیمات مهم

| تنظیم | مقدار | توضیح |
|---|---|---|
| `pull.rebase` | true | pull همیشه rebase |
| `push.autoSetupRemote` | true | `git push` روی branch جدید خودکار |
| `fetch.prune` | true | حذف branch‌های حذف‌شده از remote |
| `rebase.autoStash` | true | stash خودکار قبل از rebase |
| `merge.conflictStyle` | zdiff3 | نمایش بهتر conflict‌ها |
| `commit.verbose` | true | نمایش diff هنگام نوشتن commit message |
| `branch.sort` | -committerdate | مرتب‌سازی branch‌ها بر اساس آخرین commit |

---

## Delta

نمایش زیبای diff در ترمینال.

```bash
git diff            # → با delta نمایش داده می‌شود
git log -p          # → با delta نمایش داده می‌شود
git show            # → با delta نمایش داده می‌شود
```

### میانبرها (در delta)

| میانبر | عملکرد |
|---|---|
| `n` | تطابق بعدی |
| `N` | تطابق قبلی |
| `q` | خروج |

**تنظیمات:** line numbers فعال، side-by-side غیرفعال، theme ansi.

---

## gh (GitHub CLI)

رابط خط فرمان GitHub.

```bash
# احراز هویت
gh auth login

# ریپو
gh repo create my-project --public
gh repo clone user/repo
gh repo view

# Issues
gh issue list
gh issue create --title "Bug" --body "Description"
gh issue view 42

# Pull Requests
gh pr list
gh pr create --title "Feature" --body "Description"
gh pr checkout 42
gh pr merge 42
gh pr review 42 --approve

# Actions
gh run list
gh run view 12345

# Release
gh release create v1.0.0 --title "v1.0.0" --notes "Release notes"
```

**تنظیمات:** `git_protocol = "ssh"` (استفاده از SSH به جای HTTPS).

---

## lazygit

رابط TUI برای git. مدیریت ریپو بدون تایپ دستورات.

```bash
lazygit             # باز کردن lazygit
```

### میانبرها

| میانبر | عملکرد |
|---|---|
| `1-5` | سوییچ بین پنل‌ها |
| `Space` | stage/unstage فایل |
| `a` | stage همه |
| `c` | commit |
| `C` | commit با editor |
| `P` | push |
| `p` | pull |
| `m` | resolve conflict (ours/theirs) |
| `e` | باز کردن فایل در ادیتور |
| `o` | باز کردن در مرورگر |
| `d` | discard changes |
| `z` | undo |
| `Z` | redo |
| `/` | جستجو |
| `q` | خروج |

### پنل‌ها

1. **Status** — branch فعلی، stash، merge state
2. **Files** — فایل‌های تغییریافته
3. **Branches** — branch‌های محلی
4. **Commits** — تاریخچه commits
5. **Stash** — stash‌ها

---

## gh-dash

داشبورد TUI برای GitHub.

```bash
gh-dash             # باز کردن داشبورد
```

**نمایش:**
- PRهای باز شما
- Issueهای اختصاص‌داده شده
- نوتیفیکیشن‌ها
- GitHub Actions workflowها
