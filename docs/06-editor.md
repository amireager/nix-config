# ۰۶ — Neovim: Editor، IDE، REPL و Debugger

این configuration روی Neovim 0.11+ و API native جدید LSP ساخته شده است. هدف آن تبدیل editor به یک IDE بسته و مستقل نیست؛ editor یک لایه‌ی پایدار دارد و toolchain سنگین پروژه از devShell/direnv می‌آید.

```text
Nix/Home Manager
├── Neovim binary و providerها
├── pluginها
├── ابزارهای روزمره: Python/Nix/Lua/Shell/Web LSP و formatter
└── Lua config

Project environment
├── rust-analyzer + LLDB
├── gopls + Delve
├── compiler/runtime
└── dependencyهای همان پروژه
```

---

# ساختار فعلی

```text
modules/home/dev/nvim/
├── default.nix
└── lua/
    ├── options.lua
    ├── keymaps.lua
    ├── autocmds.lua
    ├── ui.lua
    ├── snacks.lua
    ├── completion.lua
    ├── lsp.lua
    ├── format-lint.lua
    ├── git.lua
    ├── productivity.lua
    ├── navigation.lua
    ├── run.lua
    ├── markdown.lua
    ├── dap.lua
    ├── ai.lua
    └── ux.lua
```

`default.nix` plugin و binaryها را از Nix می‌آورد و فایل‌های Lua را به ترتیب startup وارد `init.lua` می‌کند. تقریباً تمام plugin setupها با `pcall(require, ...)` محافظت شده‌اند؛ نبودن یک plugin باید همان feature را غیرفعال کند، نه startup کامل editor را.

کانفیگ portable غیر-Nix و Lazy backend یک refactor مستقل آینده است؛ وضعیت فعلی Nix-first و declarative است.

---

# اولین قانون: Space و which-key

`<leader>` کلید Space است. اگر shortcut را فراموش کردید:

1. Space را بزنید؛
2. کمی صبر کنید؛
3. گروه و توضیح which-key را بخوانید.

| گروه | حوزه |
| :--- | :--- |
| `<leader>a` | AI / CodeCompanion |
| `<leader>b` | buffer |
| `<leader>c` | code، format و rename file |
| `<leader>d` | DAP debugger |
| `<leader>e` | explorer |
| `<leader>f` | find/picker |
| `<leader>g` | Git |
| `<leader>l` | LSP و diagnostic |
| `<leader>m` | Markdown |
| `<leader>r` | run/REPL |
| `<leader>t` | tab/terminal |
| `<leader>u` | UI toggle |
| `<leader>w` | window |
| `<leader>x` | Trouble/listها |

مرجع کامل: [keys.md](keys.md).

---

# startup و dashboard

Snacks dashboard دو pane دارد:

- shortcutها؛
- recent file و project؛
- Git status زنده برای directory فعلی.

بازکردن یک file مشخص dashboard را دور می‌زند:

```bash
nvim modules/nixos/core.nix
nvim +120 modules/home/cli/fish.nix
nvim +'/pattern' file.txt
```

برای مقایسه:

```bash
nvim -d old.nix new.nix
```

Home Manager همچنین `vi`, `vim` و `vimdiff` را به Neovim وصل می‌کند.

---

# Navigation پایه

| کلید | رفتار |
| :--- | :--- |
| `j` / `k` | روی wrapped line بصری حرکت می‌کند؛ count رفتار واقعی line را حفظ می‌کند |
| `H` / `M` / `L` | بالا، وسط و پایین viewport |
| `<Tab>` / `<S-Tab>` | buffer بعدی/قبلی |
| `<C-h/j/k/l>` | حرکت میان splitها |
| `<C-arrow>` | resize split |
| `]T` / `[T` | tab بعدی/قبلی |
| `<C-d>` / `<C-u>` | نیم‌صفحه با recenter |
| `n` / `N` | نتیجه‌ی search با recenter |

Buffer با tab یک چیز نیست:

- buffer فایل بازشده است؛
- window یک view روی buffer است؛
- tab مجموعه‌ای از windowهاست؛
- scope.nvim bufferline هر tab را ایزوله می‌کند.

---

# Flash و حرکت ساختاری

## Flash

```text
s  → query-driven jump
S  → Treesitter node selection
r  → remote motion در operator-pending
R  → Treesitter search
```

مثال:

```text
y r <label>   yank یک target دور بدون حرکت cursor
c s <label>   تغییر تا target انتخابی
```

`f/t` نیز multi-line شده‌اند و `;`/`,` repeat را حفظ می‌کنند.

## Treesitter text objects

```text
daf  delete around function
vif  select inside function
vac  select around class
cia  change inside argument
]f   function بعدی
[f   function قبلی
]k   class بعدی
[k   class قبلی
```

Swap argument:

```text
<leader>cs  swap با argument بعدی
<leader>cS  swap با argument قبلی
```

---

# Search و Snacks Picker

## entryهای سریع

| کلید | Picker |
| :--- | :--- |
| `<leader><space>` | smart picker |
| `<leader>/` | grep project |
| `<leader>,` | bufferها |
| `<leader>:` | command history |
| `<leader>n` | notification history |
| `<leader>fr` | resume picker قبلی |

## فایل و project

```text
<leader>ff  files
<leader>fg  Git files
<leader>fb  buffers
<leader>fp  projects
<leader>fl  lineهای buffer
<leader>fw  word/selection
```

داخل picker:

- `Alt+h`: hidden؛
- `Alt+i`: ignored؛
- preview و layout با Snacks مدیریت می‌شود.

## LSP pickerها

```text
gd            definition
gr            reference
gI            implementation
gy            type definition
<leader>fs    document symbols
<leader>fS    workspace symbols
<leader>fd    buffer diagnostics
<leader>fD    workspace diagnostics
```

## Explorer

```text
<leader>ee  explorer project
<leader>ef  explorer کنار file جاری
<leader>ey  Yazi در tmux split
```

Yazi command به tmux نیاز دارد؛ بیرون از tmux split ساخته نمی‌شود.

---

# LSP ownership

## Global و همیشه در دسترس

| زبان/format | server/tool |
| :--- | :--- |
| Python | Pyright، Ruff |
| Nix | nixd، Alejandra، Statix، Deadnix |
| Lua | lua-language-server، StyLua |
| Shell | bash-language-server، ShellCheck، shfmt |
| TOML | Taplo |
| YAML | yaml-language-server |
| Markdown | Marksman |
| JS/TS | typescript-language-server |
| HTML/CSS/JSON | vscode-langservers-extracted |
| Tailwind/Emmet | serverهای مربوط |

## Project-only

| زبان | devShell | server/debugger |
| :--- | :--- | :--- |
| Rust | `dev rust` | rust-analyzer، lldb-dap |
| Go | `dev go` | gopls، dlv |
| C/C++ | `dev build` | lldb-dap، gdb |

Lua config serverهای project-only را می‌شناسد؛ نبودن executable تا وقتی filetype مربوط باز نشده failure startup نیست.

## diagnosis

داخل Neovim:

```vim
:LspInfo
:checkhealth vim.lsp
```

در shell:

```bash
command -v rust-analyzer
command -v gopls
command -v pyright
```

اگر binary نیست، Neovim را داخل shell مناسب باز کنید یا direnv را فعال کنید.

## actionها

| کلید | عمل |
| :--- | :--- |
| `K` | hover |
| `<leader>lk` | signature help |
| `<leader>lr` | rename symbol |
| `<leader>la` | code action |
| `<leader>li` | LSP info |
| `[d` / `]d` | diagnostic قبلی/بعدی |
| `<leader>ld` | diagnostic خط |
| `<leader>lq` | diagnosticها به quickfix |

---

# Completion

Blink.cmp sourceهای زیر را ترکیب می‌کند:

```text
lazydev → LSP → path → snippets → buffer
```

Lazydev در فایل‌های config Neovim type/moduleهای `vim.*` را به LuaLS می‌دهد.

| کلید | رفتار completion |
| :--- | :--- |
| `<C-Space>` | بازکردن menu/documentation |
| `<C-j>` / `<C-k>` | انتخاب بعدی/قبلی |
| `<C-d>` / `<C-u>` | scroll documentation |
| `<C-e>` | بستن menu |
| Tab | preset super-tab |

Completion fuzzy Rust را ترجیح می‌دهد و اگر implementation در دسترس نباشد warning قابل مشاهده می‌دهد.

---

# Format و lint

Conform formatter را بر اساس filetype انتخاب می‌کند:

| filetype | formatter |
| :--- | :--- |
| Python | Ruff format + organize imports |
| JS/TS/HTML/CSS/JSON/Markdown/YAML | Prettier |
| Rust | rustfmt |
| Lua | StyLua |
| Nix | Alejandra |
| Shell | shfmt / fish_indent |
| TOML | Taplo |

```text
<leader>cf  format دستی file یا selection
<leader>uf  toggle autoformat همین buffer
<leader>uF  toggle autoformat global session
```

Autoformat timeout برابر 1200ms و LSP fallback است. اگر formatter external نیست، ابتدا PATH/project environment را بررسی کنید؛ config را با formatter دوم پنهان نکنید.

بعد از format تغییر را بخوانید:

```vim
:write
:DiffviewOpen
```

---

# Git workflow

## Hunk-level

| کلید | عمل |
| :--- | :--- |
| `]h` / `[h` | hunk بعدی/قبلی |
| `<leader>gp` | preview hunk |
| `<leader>gs` | stage hunk/selection |
| `<leader>gr` | reset hunk/selection |
| `<leader>gA` | stage buffer |
| `<leader>gR` | reset buffer |
| `<leader>gb` | blame کامل خط |
| `<leader>gd` | diff buffer |
| `<leader>gD` | diff با revision قبلی |
| `vih` | انتخاب hunk |

Reset destructive است؛ preview را قبل از reset بخوانید.

## Repository-level

```text
<leader>gn  Neogit
<leader>gc  commit UI
<leader>gg  Lazygit
<leader>gL  Git log
<leader>gF  log file جاری
<leader>gv  Diffview
<leader>gh  project history
<leader>gH  file history
```

Workflow پیشنهادی:

1. `]h` میان تغییرها؛
2. `<leader>gp` برای preview؛
3. `<leader>gs` stage انتخابی؛
4. `<leader>gn` یا Lazygit برای مرور staged set؛
5. commit فقط بعد از خواندن diff نهایی.

---

# Python REPL و cell workflow

مارکرهای پشتیبانی‌شده:

```python
# %%
# <codecell>
```

| کلید | عمل |
| :--- | :--- |
| `<leader>rp` | IPython در tmux pane |
| `<leader>rc` | cell جاری |
| `<leader>rl` | خط جاری |
| `<leader>rs` | selection |
| `<leader>rf` | کل file |
| `<leader>rn` / `]C` | cell بعدی |
| `<leader>rN` / `[C` | cell قبلی |

نمونه:

```python
# %%
from pathlib import Path
files = list(Path(".").rglob("*.nix"))
len(files)

# %%
from collections import Counter
Counter(path.parts[0] for path in files)
```

این workflow برای exploration است. DAP برای سؤال «چرا control flow یا state اشتباه است؟» استفاده می‌شود.

---

# DAP Debugger

## adapter ownership

| زبان | adapter | منبع |
| :--- | :--- | :--- |
| Python | debugpy | global Neovim closure |
| Lua/Neovim | one-small-step-for-vimkind | global plugin |
| Rust/C/C++/Zig | lldb-dap | `dev rust` / `dev build` |
| C/C++ fallback | GDB DAP | `dev build` |
| Go | Delve | `dev go` |

اگر adapter project-only روی PATH نباشد، config command shell مناسب را در notification نشان می‌دهد.

## breakpoint و execution

```text
<leader>db  toggle breakpoint
<leader>dB  conditional breakpoint
<leader>dl  log point
<leader>dc  start/continue
<leader>dC  run to cursor
<leader>do  step over
<leader>di  step into
<leader>dO  step out
<leader>dr  restart
<leader>dq  terminate
```

Conditional breakpoint نمونه:

```text
item.id == 47
```

این breakpoint در loop بزرگ فقط روی state هدف توقف می‌کند؛ مزیت اصلی debugger نسبت به print پراکنده همین است.

## UI و inspection

```text
<leader>du  DAP UI
<leader>de  evaluate expression
<leader>dR  REPL
<leader>dj/dk stack frame down/up
<leader>dX  clear all breakpoints
```

Breakpointها هنگام خروج در مسیر زیر ذخیره می‌شوند:

```text
~/.local/state/nvim/dap-breakpoints.json
```

فقط fileهای موجود restore می‌شوند.

## Python test

```text
<leader>dt  test method
<leader>dT  test class
<leader>ds  debug visual selection
```

## debug خود Neovim

در instance هدف:

```vim
:DapLuaServer
```

سپس از instance دوم config Lua attach شود. Port پیش‌فرض فقط loopback است.

---

# Markdown

Render Markdown ظاهر heading، table، list و checkbox را داخل buffer بهتر می‌کند:

```text
<leader>um  toggle render
<leader>mt  toggle rendering
<leader>me  enable rendering
<leader>md  disable rendering
```

Marksman symbol/link intelligence را می‌دهد و Prettier format را انجام می‌دهد.

---

# AI در editor

CodeCompanion به gateway محلی وصل می‌شود و فقط با action صریح request می‌فرستد.

```text
<leader>aa  chat
<leader>ai  inline edit
<leader>ap  action palette
<leader>as  selection → chat
<leader>ae  explain
<leader>af  fix
<leader>at  tests
<leader>ad  diagnostic explanation
<leader>aC  commit message
<leader>ag  agent chat
<leader>am  model picker
<leader>a?  gateway/model status
```

Inline diff:

```text
g1  accept all
g2  accept current
g3  reject current
```

هر tool که disk/shell را لمس کند باید confirmation داشته باشد. Generated command قبل از Enter روی command line نمایش داده می‌شود.

Diagnosis:

```vim
:AIDoctor
```

جزئیات privacy، gateway و local modelها: [۰۷ AI](07-ai.md).

---

# UI toggleها

| کلید | قابلیت |
| :--- | :--- |
| `<leader>uz` | dim/focus |
| `<leader>uZ` | zen |
| `<leader>ui` | indent guide |
| `<leader>us` | smooth scroll |
| `<leader>uw` | word highlight |
| `<leader>ud` | diagnostic display |
| `<leader>uc` | conceal |
| `<leader>uN` | notification popup |
| `<leader>un` | dismiss notification |
| `<leader>um` | Markdown render |
| `<leader>ub` | line blame |
| `<leader>ug` | deleted Git lines |
| `<leader>ul` | relative number |
| `<leader>uW` | wrap |
| `<leader>uS` | spell |
| `<leader>ux` | Treesitter context |

Themeهای Nightfox، Catppuccin و Tokyonight نصب‌اند و picker رنگ از `<leader>fC` باز می‌شود. Default Nightfox با palette سفارشی است.

---

# Mini modules

| module | کاربرد | نمونه |
| :--- | :--- | :--- |
| mini.pairs | pair خودکار | bracket/quote |
| mini.ai | text object بهتر | `daf`, `vic` |
| mini.surround | surround | `gsa`, `gsd`, `gsr` |
| mini.comment | comment | `gcc`, `gc` |
| mini.move | جابه‌جایی | `Alt+h/j/k/l` |
| mini.splitjoin | split/join construct | `gsj` |
| mini.bracketed | حرکت bracketed | buffer/comment/diagnostic/... |
| mini.bufremove | حذف buffer بدون layout damage | buffer keyها |
| mini.trailspace | نمایش/trim whitespace | `<leader>cw` |

Mini.jump2d عمداً فعال نیست؛ Flash جای آن را گرفته است.

---

# troubleshooting ترتیب‌دار

## startup error

```bash
nvim --clean
nvim --headless '+checkhealth' +qa
```

`--clean` نشان می‌دهد مشکل از binary/runtime پایه است یا config. Headless check ممکن است plugin/tool runtime را load کند؛ output را کامل بخوانید.

## plugin موجود نیست

داخل Neovim:

```vim
:lua print(vim.inspect(vim.api.nvim_list_runtime_paths()))
:checkhealth
```

در Nix-first config plugin manager runtime نداریم؛ package باید در `default.nix` و generation فعال باشد.

## formatter کار نمی‌کند

```vim
:ConformInfo
```

و در shell:

```bash
command -v alejandra
command -v prettier
command -v ruff
```

## picker نتیجه ندارد

```bash
rg --files --hidden -g '!.git' | head
```

اگر rg هم file را نمی‌بیند، ignore rule یا directory فعلی را بررسی کنید.

## performance

```bash
nvim --startuptime /tmp/nvim-startup.log +qa
sort -k2 -nr /tmp/nvim-startup.log | head
```

Startup profile را در چند run و روی cache warm مقایسه کنید؛ یک run تصادفی benchmark نیست.

---

بعدی: [۰۷ AI](07-ai.md)
