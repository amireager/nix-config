# مرجع کامل کلیدها و فرمان‌های روزمره

این فایل کارت مرجع bindingهای اختصاصی این repository است. برای چرایی workflowها به [فصل دسکتاپ](05-desktop.md)، [فصل Neovim](06-editor.md) و [فصل CLI](04-cli.md) رجوع کنید.

- **`Mod`**: کلید Super/Windows
- **`CapsLock`**: ضربه‌ی کوتاه `Escape`؛ نگه‌داشتن `Mod`
- **`<leader>`** در Neovim: کلید `Space`
- حروف بزرگ مثل `F` یا `X` یعنی همراه Shift.
- کلیدهای plugin فقط وقتی plugin با موفقیت load شده باشد فعال‌اند.
- برای کشف زنده‌ی کلیدهای Neovim، `<leader>` را بزنید و منوی Which-key را ببینید؛ `<leader>fk` نیز همه‌ی keymapها را جست‌وجو می‌کند.

---

# دسکتاپ — Niri و Noctalia

## راهنما و پنل‌ها

| کلید | عملکرد |
| :--- | :--- |
| `Mod + Shift + /` | Hotkey overlay خود Niri |
| `Mod + Space` | Launcher در Noctalia |
| `Mod + S` | Control Center |
| `Mod + ,` | تنظیمات Noctalia |
| `Mod + I` | Caffeine؛ توقف/ادامه‌ی موقت رفتار idle |

## برنامه‌ها

| کلید | عملکرد |
| :--- | :--- |
| `Mod + Return` | Kitty |
| `Mod + /` | Kitty با class ترمینال سریع |
| `Mod + B` | Zen Browser |
| `Mod + E` | Thunar |
| `Mod + Shift + E` | Yazi داخل Kitty |
| `Mod + V` | انتخاب از Cliphist و کپی نتیجه |
| `Mod + N` | انتخاب Wi-Fi با Fuzzel |
| `Mod + Alt + C` | ماشین‌حساب Fuzzel و کپی نتیجه |

## فوکوس و جابه‌جایی

| کلید | عملکرد |
| :--- | :--- |
| `Mod + H/L` یا `Mod + ←/→` | فوکوس ستون چپ/راست |
| `Mod + K/J` یا `Mod + ↑/↓` | فوکوس پنجره‌ی بالا/پایین در ستون |
| `Mod + Shift + H/L` یا `Mod + Ctrl + ←/→` | جابه‌جایی ستون چپ/راست |
| `Mod + Shift + K/J` یا `Mod + Ctrl + ↑/↓` | جابه‌جایی پنجره بالا/پایین در ستون |
| `Mod + C` | وسط‌چین کردن ستون |
| `Mod + W` | وارد کردن پنجره در ستون کناری |
| `Mod + Shift + W` یا `Mod + .` | بیرون آوردن پنجره از ستون |
| `Mod + G` | تغییر نمایش ستون بین stacked و tabbed |
| `Mod + T` | تغییر tiled/floating |
| `Mod + Escape` | تغییر Keyboard Shortcuts Inhibit |

## اندازه و نمایش

| کلید | عملکرد |
| :--- | :--- |
| `Mod + R` | عرض preset بعدی ستون |
| `Mod + -/=` | کاهش/افزایش عرض ستون به اندازه‌ی ۱۰٪ |
| `Mod + F` | maximize ستون |
| `Mod + Shift + F` | fullscreen پنجره |
| `Mod + Ctrl + F` | windowed fullscreen |

## Overview و Workspace

| کلید | عملکرد |
| :--- | :--- |
| `Mod + Tab` | Overview |
| `Mod + Shift + Tab` | workspace قبلی |
| `Mod + Wheel Up/Down` | workspace بالا/پایین |
| `Mod + 1…5` | فوکوس workspace شماره‌ی ۱ تا ۵ |
| `Mod + Shift + 1…5` | انتقال ستون به workspace شماره‌ی ۱ تا ۵ |

## نشست، تصویر و رسانه

| کلید | عملکرد |
| :--- | :--- |
| `Mod + Q` | بستن پنجره |
| `Mod + Shift + Q` | خروج از Niri |
| `Mod + X` | قفل با Noctalia |
| `Mod + Shift + X` | fallback قفل با Swaylock |
| `Mod + P` | screenshot ناحیه |
| `Mod + Shift + P` | screenshot نمایشگر |
| `Mod + Alt + P` | screenshot پنجره |
| `Mod + Ctrl + P` | screenshot ناحیه و کپی مستقیم |
| `Mod + Alt + R` | شروع/توقف ضبط صفحه |
| `Mod + Alt + K` | روشن/خاموش کردن نمایش کلیدهای فشرده |
| `XF86AudioRaise/LowerVolume` | افزایش/کاهش صدا، حتی روی lock screen |
| `XF86AudioMute` | mute، حتی روی lock screen |
| `XF86MonBrightnessUp/Down` | روشنایی، حتی روی lock screen |
| `Mod + Touchpad Scroll Down/Up` | افزایش/کاهش صدا |

---

# Neovim 0.11+

## پایه، حرکت و فایل

| Mode | کلید | عملکرد |
| :--- | :--- | :--- |
| Insert | `jk` | خروج به Normal mode |
| Normal | `<Esc>` | پاک کردن highlight جست‌وجو |
| Normal | `j/k` | حرکت visual-line روی lineهای wrap‌شده؛ count رفتار اصلی را حفظ می‌کند |
| Normal | `<C-d>` / `<C-u>` | نیم‌صفحه پایین/بالا و وسط‌چین cursor |
| Normal | `n/N` | نتیجه‌ی بعدی/قبلی search و وسط‌چین cursor |
| Normal | `<leader>s` | ذخیره |
| Normal | `<leader>q` | خروج از window |
| Normal | `<leader>Q` | خروج از همه‌ی windowها |
| پنجره‌های موقت | `q` | بستن help/quickfix و bufferهای موقت تعریف‌شده |

## Window، Buffer و Tab

| کلید | عملکرد |
| :--- | :--- |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | فوکوس window چپ/پایین/بالا/راست |
| `<leader>wv` / `<leader>ws` | split عمودی/افقی |
| `<leader>wq` / `<leader>wo` | بستن window / بستن windowهای دیگر |
| `<leader>wh` / `<leader>wj` / `<leader>wk` / `<leader>wl` | فوکوس window در جهت مربوط |
| `<C-Up>` / `<C-Down>` | افزایش/کاهش ارتفاع window |
| `<C-Left>` / `<C-Right>` | کاهش/افزایش عرض window |
| `<Tab>` / `<S-Tab>` | buffer بعدی/قبلی |
| `<leader>bb` | alternate buffer |
| `<leader>bn` / `<leader>bp` | buffer بعدی/قبلی |
| `<leader>bd` / `<leader>bD` | حذف buffer / حذف اجباری buffer |
| `<leader>bo` | حذف bufferهای دیگر |
| `<leader>tn` / `<leader>tc` / `<leader>to` | tab جدید / بستن tab / بستن tabهای دیگر |
| `<leader>tl` / `<leader>th` یا `]T` / `[T` | tab بعدی/قبلی |

## Completion — Blink

| کلید | عملکرد در completion menu |
| :--- | :--- |
| `<Tab>` / `<S-Tab>` | preset نوع super-tab؛ انتخاب/پذیرش و حرکت متناسب با context |
| `<C-space>` | نمایش completion یا documentation |
| `<C-e>` | بستن menu |
| `<C-j>` / `<C-k>` | item بعدی/قبلی |
| `<C-d>` / `<C-u>` | scroll پایین/بالای documentation |

## Explorer و actionهای سریع

| کلید | عملکرد |
| :--- | :--- |
| `<leader><space>` | Smart Find |
| `<leader>,` | لیست bufferها |
| `<leader>/` | grep پروژه |
| `<leader>:` | command history |
| `<leader>n` | notification history |
| `<leader>ee` | Snacks Explorer |
| `<leader>ef` | Explorer در directory فایل جاری |
| `<leader>ey` | Yazi در pane سمت راست tmux |
| `Alt-i` در Picker | toggle فایل‌های gitignored |
| `Alt-h` در Picker | toggle فایل‌های hidden |

## Pickerهای `<leader>f`

| کلید | داده‌ی قابل جست‌وجو |
| :--- | :--- |
| `<leader>ff` / `<leader>fg` / `<leader>fb` | همه‌ی فایل‌ها / فایل‌های Git / bufferها |
| `<leader>fh` / `<leader>fk` / `<leader>fc` | Help / keymapها / commandها |
| `<leader>fp` / `<leader>fm` / `<leader>fa` | projectها / man pageها / autocmdها |
| `<leader>fu` / `<leader>fj` / `<leader>fq` | undo history / jump list / quickfix |
| `<leader>fR` / `<leader>fH` / `<leader>fC` / `<leader>fI` | registerها / highlightها / colorschemeها / icon و emoji |
| `<leader>ft` / `<leader>fl` | TODOها / خط‌های buffer جاری |
| `<leader>fs` / `<leader>fS` | symbolهای document / workspace |
| `<leader>fw` | کلمه‌ی زیر cursor یا selection |
| `<leader>fd` / `<leader>fD` | diagnosticهای buffer / workspace |
| `<leader>fr` | ادامه‌ی آخرین Picker |

## LSP و Diagnostic

این mappingها برای buffer دارای LSP فعال‌اند؛ `gd/gr/gI/gy` نتیجه را با Snacks Picker نشان می‌دهند.

| کلید | عملکرد |
| :--- | :--- |
| `gd` | definitionها |
| `gr` | referenceها |
| `gI` | implementationها |
| `gy` | type definitionها |
| `K` | Hover documentation |
| `<leader>lk` | Signature help |
| `<leader>lr` | Rename symbol |
| `<leader>la` | Code action؛ در Visual روی selection |
| `<leader>lf` | format مستقیم با LSP |
| `<leader>li` | `:LspInfo` |
| `[d` / `]d` | diagnostic قبلی/بعدی |
| `<leader>ld` | diagnostic خط در float |
| `<leader>lq` | انتقال diagnosticها به quickfix |
| `<leader>cR` | تغییر نام فایل جاری و اطلاع‌دادن به clientهای LSP |
| `<leader>cf` | format با Conform و fallback به LSP؛ Visual برای selection |

`<leader>cf` مسیر معمول format است. `<leader>lf` فراخوانی مستقیم LSP و برای diagnosis یا server خاص مفید است.

## حرکت سریع و ساختاری

| Mode | کلید | عملکرد |
| :--- | :--- | :--- |
| Normal/Visual/Operator | `s` | Flash jump |
| Normal/Visual/Operator | `S` | انتخاب Treesitter با Flash |
| Operator | `r` | Remote Flash؛ مانند `yr` و سپس label |
| Operator/Visual | `R` | Treesitter search |
| Command-line search | `<C-s>` | toggle labelهای Flash در `/` یا `?` |
| Normal/Visual | `H/M/L` | بالا/وسط/پایین screen؛ `H/L` به scrolloff احترام می‌گذارند |
| Normal | `[x` | رفتن به header context جاری |
| Normal/Visual/Operator | `af/if` | function کامل/داخل function |
| Normal/Visual/Operator | `ac/ic` | class کامل/داخل class |
| Normal/Visual/Operator | `aa/ia` | argument کامل/داخل argument |
| Normal/Visual/Operator | `ai/ii` | conditional کامل/داخل conditional |
| Normal/Visual/Operator | `al/il` | loop کامل/داخل loop |
| Normal/Visual/Operator | `a/` | comment کامل |
| Normal | `]f/[f` | شروع function بعدی/قبلی |
| Normal | `]F/[F` | پایان function بعدی/قبلی |
| Normal | `]k/[k` | شروع class بعدی/قبلی |
| Normal | `]K/[K` | پایان class بعدی/قبلی |
| Normal | `]a/[a` | argument بعدی/قبلی |
| Normal | `<leader>cs` / `<leader>cS` | جابه‌جایی argument با بعدی/قبلی |

## Mini editing

| کلید | عملکرد |
| :--- | :--- |
| `gsa/gsd/gsr` | افزودن/حذف/جایگزینی surround |
| `gsf/gsF/gsh/gsn` | پیدا کردن راست/چپ، highlight و تغییر search range surround |
| `gsj` | split/join ساختار |
| `gcc` یا operator `gc` | comment خط یا motion/selection |
| `Alt-h/j/k/l` | جابه‌جایی selection یا خط چپ/پایین/بالا/راست |
| `[b/]b`, `[c/]c`, `[d/]d`, `[f/]f` | buffer، comment، diagnostic و file قبلی/بعدی |
| `[i/]i`, `[j/]j`, `[l/]l`, `[o/]o` | indent، jump، location و oldfile قبلی/بعدی |
| `[q/]q`, `[t/]t`, `[u/]u`, `[w/]w`, `[y/]y` | quickfix، treesitter، undo، window و yank قبلی/بعدی |
| `<leader>cw` | trim trailing whitespace و lineهای خالی انتهایی |

بعضی bracket motionها عمداً توسط mapping دقیق‌تر override می‌شوند: `[d/]d` از LSP، `[f/]f` از Treesitter و `[c/]c` برای comment باقی می‌ماند.

## Git

| کلید | عملکرد |
| :--- | :--- |
| `]h/[h` | hunk بعدی/قبلی |
| `<leader>gs` / `<leader>gr` | stage/reset hunk؛ Visual برای range |
| `<leader>gA` / `<leader>gR` | stage/reset کل buffer |
| `<leader>gp` | preview hunk |
| `<leader>gb` / `<leader>gt` | blame کامل خط / toggle inline blame |
| `<leader>gd` / `<leader>gD` | diff buffer / diff با `~` |
| `<leader>gn` / `<leader>gc` | Neogit / Neogit commit UI |
| `<leader>gg` | Lazygit |
| `<leader>gF` / `<leader>gL` | Git log فایل جاری / کل repository در Lazygit |
| `<leader>gB` / `<leader>gl` | Picker branchها / Git log |
| `<leader>go` | باز کردن target Git در browser |
| `<leader>gv` / `<leader>gV` | باز/بستن Diffview |
| `<leader>gh` / `<leader>gH` | تاریخچه‌ی project / فایل جاری در Diffview |
| `ih` در Operator/Visual | انتخاب hunk به‌عنوان text object |

کلیدهای stage/reset repository را تغییر می‌دهند؛ preview و diff را قبل از commit بخوانید.

## Debug — DAP

| کلید | عملکرد |
| :--- | :--- |
| `<leader>db` | toggle breakpoint |
| `<leader>dB` | breakpoint شرطی |
| `<leader>dl` | log point بدون توقف |
| `<leader>dX` | پاک کردن همه‌ی breakpointها |
| `<leader>dc` / `<leader>dC` | start/continue / run to cursor |
| `<leader>do` / `<leader>di` / `<leader>dO` | step over / into / out |
| `<leader>dr` / `<leader>dq` | restart / terminate session |
| `<leader>dR` | DAP REPL |
| `<leader>dj` / `<leader>dk` | frame پایین/بالای stack |
| `<leader>du` | toggle DAP UI |
| `<leader>de` | evaluate expression؛ Normal یا Visual |
| `<leader>dt` / `<leader>dT` | debug تست Python زیر cursor / class |
| `<leader>ds` در Visual | debug selection پایتون |

## AI — CodeCompanion

این actionها صریح و on-demand هستند. Agent می‌تواند بیرون sandbox command اجرا و فایل را تغییر دهد؛ confirmation را جدی بخوانید.

| Mode | کلید | عملکرد |
| :--- | :--- | :--- |
| Normal/Visual | `<leader>aa` | toggle chat |
| Normal/Visual | `<leader>ap` | palette actionها |
| Visual | `<leader>as` | افزودن selection به chat |
| Normal | `<leader>ah` | تاریخچه‌ی chat |
| Normal | `<leader>ax` | تولید command روی `:` برای review پیش از اجرا |
| Normal/Visual | `<leader>ai` | inline edit با diff |
| Visual | `<leader>ae` | توضیح selection |
| Visual | `<leader>af` | اصلاح selection |
| Visual | `<leader>at` | نوشتن test برای selection |
| Visual | `<leader>ad` | توضیح diagnostic در context selection |
| Normal | `<leader>aC` | پیشنهاد commit message |
| Normal | `<leader>ag` | Agent mode با confirmation صریح |
| Normal | `<leader>am` | model پیش‌فرض chatهای جدید از gateway |
| Normal | `<leader>a?` | status gateway و model |

داخل diff مربوط به inline edit، bindingهای plugin مانند `g2` برای قبول change، `g3` برای رد change و `g1` برای قبول همه استفاده می‌شوند؛ diff را پیش از پذیرش بخوانید.

## Python REPL

| Mode | کلید | عملکرد |
| :--- | :--- | :--- |
| Normal | `<leader>rp` | باز کردن IPython در pane سمت راست tmux |
| Normal | `<leader>rl` | ارسال خط جاری |
| Visual | `<leader>rs` | ارسال selection |
| Normal | `<leader>rc` | ارسال cell جاری با مرز `# %%` |
| Normal | `<leader>rf` | ارسال کل فایل |
| Normal | `<leader>rn` / `<leader>rN` یا `]C` / `[C` | cell بعدی/قبلی |

## Trouble و TODO

| کلید | عملکرد |
| :--- | :--- |
| `<leader>xt` | TODOها در Trouble |
| `<leader>xx` / `<leader>xX` | diagnosticهای workspace / buffer |
| `<leader>xs` | symbolها |
| `<leader>xl` | LSP referenceها |
| `<leader>xL` / `<leader>xQ` | location list / quickfix list |

`<leader>ft` Picker فازی TODO است؛ `<leader>xt` لیست ماندگار برای مرور موردبه‌مورد.

## Markdown، UI و Toggleها

| کلید | عملکرد |
| :--- | :--- |
| `<leader>mt` / `<leader>me` / `<leader>md` | toggle / enable / disable رندر Markdown |
| `<leader>um` | alias toggle رندر Markdown |
| `<leader>uz` / `<leader>uZ` | focus/dim / Zen mode |
| `<leader>ui` | indent guideها |
| `<leader>un` / `<leader>uN` | بستن notificationها / toggle popupها |
| `<leader>us` | smooth scroll |
| `<leader>uw` | highlight کلمه |
| `<leader>ud` | diagnostic display |
| `<leader>uc` | conceal |
| `<leader>uf` / `<leader>uF` | autoformat برای buffer / global |
| `<leader>ul` | relative line number |
| `<leader>uW` | word wrap |
| `<leader>uS` | spell check |
| `<leader>ux` | Treesitter context |
| `<leader>ub` | Git blame خط |
| `<leader>ug` | خط‌های حذف‌شده‌ی Git |
| `<leader>fC` | تغییر colorscheme با Picker |

## Terminal

| کلید | عملکرد |
| :--- | :--- |
| `<leader>tt` | toggle terminal در Snacks |
| `<leader>tf` | Fish terminal پایین با ارتفاع حدود ۳۰٪ |

---

# فرمان‌های سریع Shell

## Dev

| فرمان | عملکرد |
| :--- | :--- |
| `dev` | لیست سریع environmentها بدون Flake evaluation |
| `dev -i` | انتخاب تعاملی با FZF |
| `dev <env>` | ورود تعاملی |
| `dev <env> <command> [args...]` | اجرای مستقیم command؛ `--` بعد از env لازم نیست |
| `dev --shell bash <env>` | انتخاب Bash؛ Fish/Zsh/current نیز پشتیبانی می‌شوند |
| `dev --dry-run <env> ...` | نمایش plan بدون evaluation یا اجرا |
| `dev -w <env>` | evaluation صریح و نمایش packageها |
| `dev --keep <env>` | refresh کردن GC root بدون ورود |
| `dev --no-keep <env> ...` | اجرا بدون ایجاد/refresh root |
| `dev --roots` | registration، آخرین استفاده و closure size rootها |
| `dev --prune` | پاک کردن root قدیمی، broken و orphan با تأیید |
| `dev --unkeep <env>` | حذف حفاظت یک environment یا orphan انتخاب‌شده |
| `dev -v …` | نمایش جزئیات operation و root |

Aliasها: `c → build`، `data → python` و `default → nix`.

## Box

| فرمان | عملکرد |
| :--- | :--- |
| `box` | Home ایزوله و `.box/work → /work`؛ `$PWD` خودکار share نمی‌شود |
| `box --dry-run <cmd>` | plan بدون ساخت فایل یا process |
| `box -s host:guest <cmd>` | share فقط‌خواندنی |
| `box -S host:guest <cmd>` | share خواندنی/نوشتنی |
| `box --secure <cmd>` | environment و mount محدودتر؛ اینترنت همچنان فعال است |
| `box --net none <cmd>` | قطع network |
| `box -e <cmd>` | Home، tmp و work موقت |
| `box --mem 4G <cmd>` | محدودیت RAM |
| `box --status` | وضعیت و storage محلی |
| `box --inspect <cmd>` | trace خلاصه‌ی دسترسی target |
| `box --inspect-all <cmd>` | trace کامل‌تر |

## عملیات سیستم و proxy

| فرمان | عملکرد |
| :--- | :--- |
| `proxy_on [port]` / `proxy_off` | proxy shell جاری |
| `px <command>` | اجرای یک command از مسیر proxychains |
| `nix_proxy test [port]` / `nix_proxy on [port]` / `nix_proxy off` | بررسی و مدیریت proxy موقت nix-daemon |
| `bld` | build بدون activation |
| `tst` | activation موقت برای تست |
| `sw` | build و switch؛ فقط پس از review/test |
| `nh os switch --rollback` | بازگشت و switch به generation قبلی |
| `nh clean all --keep 5` | حذف generationهای قدیمی؛ با آگاهی از GC rootها |

---

# Workflowهای ترکیبی

## review و stage یک تغییر Git

```text
]h / [h          حرکت بین hunkها
<leader>gp       preview
<leader>gs       stage hunk
<leader>gn       Neogit
<leader>gc       commit UI
```

## فهم symbol و اثر آن

```text
<leader>fs       symbolهای document
<leader>fS       symbolهای workspace
gd               definition
gr               referenceها
K                hover/type
<C-o>            بازگشت در jump list
```

## Diagnostic تا اصلاح

```text
]d / [d          diagnostic بعدی/قبلی
<leader>ld       متن کامل
<leader>la       code action
Visual + <leader>ad  توضیح اختیاری AI برای selection
<leader>cf           format
<leader>xX       diagnosticهای buffer
```

## اجرای project داخل Box

```bash
dev python box --secure -s "$PWD:/source" \
  python -m compileall -q /source

dev web box --net none -s "$PWD:/source" \
  bash -lc 'cd /source && pnpm test'
```

## قبل از تغییر سیستم

```text
git status --short
git diff --check
nix-check             داخل dev nix
bld                   build بدون activation
tst                   activation موقت
sw                    فقط بعد از تست
```

---

برای جزئیات:

- [CLI و recipeها](04-cli.md)
- [Neovim](06-editor.md)
- [DevShell](03-dev.md)
- [Box و Audit](08-sandbox.md)
