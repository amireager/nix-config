# ۰۶ — Neovim: Editor، IDE، REPL و Debugger

این configuration روی Neovim 0.11+ و API native جدید LSP ساخته شده است. هدف آن تبدیل editor به یک IDE بسته و مستقل نیست؛ editor یک لایه‌ی پایدار دارد و toolchain سنگین پروژه از devShell/direnv می‌آید.

```text
Nix/Home Manager
├── Neovim binary (بدون providerهای Python/Node)
├── pluginها و parserهای Treesitter
├── ابزارهای روزمره: Nix/Lua/Shell/TOML/YAML/Markdown LSP و formatter
└── Lua config

Project environment (devShell + direnv)
├── dev python: Pyright، Ruff، debugpy
├── dev web: TypeScript/HTML/CSS/JSON/Tailwind/Emmet LSP، Prettier
├── dev rust / dev go / dev build: rust-analyzer، gopls، LLDB، Delve
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
    ├── treesitter.lua
    ├── run.lua
    ├── markdown.lua
    ├── dap.lua
    ├── ai.lua
    └── ux.lua
```

`default.nix` plugin و binaryها را از Nix می‌آورد و فایل‌های Lua را به ترتیب startup وارد `init.lua` می‌کند. هر فایل داخل تابع و `pcall` مستقل اجرا می‌شود: خطا یا `return` در یک فایل فقط همان بخش را متوقف می‌کند و پیام `config: <file>.lua failed` نشان می‌دهد، نه کل editor را. تقریباً تمام plugin setupها هم با `pcall(require, ...)` محافظت شده‌اند؛ نبودن یک plugin باید همان feature را غیرفعال کند.

`vim.loader.enable()` اول `init.lua` اجرا می‌شود و byte-code همه‌ی ماژول‌های Lua را cache می‌کند. اولین اجرا بعد از هر rebuild cache را می‌سازد، اجراهای بعدی سریع‌اند (در benchmark همین config: median حدود ۱۹۷ms → ۱۰۱ms).

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

# Fold، reference و scratch

```text
zc / zo / za   بستن / باز کردن / toggle fold (ساختار syntax، نه indent)
zR / zM        باز کردن / بستن همه
]r / [r        reference بعدی/قبلی کلمه‌ی زیر cursor (LSP)
<leader>.      scratch buffer برای همین project
<leader>uu     Undo tree بومی Neovim
```

Foldها با Treesitter محاسبه می‌شوند ولی در شروع چیزی بسته نیست (`foldlevelstart = 99`). `]r`/`[r` بین referenceهای کلمه‌ی زیر cursor می‌پرند و LSP لازم دارند؛ `]]`/`[[` عمداً دست‌نخورده ماندند، چون ftpluginهای Go، Python، Rust، Lua، Markdown و C آن‌ها را برای پرش بین function/section تعریف می‌کنند و map سراسری هیچ‌وقت به آن filetypeها نمی‌رسید. بافرهایی که بیرون از Neovim عوض می‌شوند (agent، Git، formatter) روی `FocusGained`، `BufEnter` (جابه‌جایی بین پنجره‌ها)، `TermClose` و `TermLeave` خودکار reload می‌شوند؛ Neovim به‌تنهایی فقط روی `FocusGained` این کار را می‌کند.

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

`lua/treesitter.lua` فعال‌سازی را انجام می‌دهد: `nvim-treesitter` روی شاخه `main` است، parserها از Nix می‌آیند و Neovim خودش highlight می‌کند. برای filetypeای که parser ندارد (مثلاً Java) syntax معمولی Vim باقی می‌ماند. text objectها با API جدید `nvim-treesitter-textobjects` بسته شده‌اند.

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

داخل tmux، Yazi در split جدید باز می‌شود؛ بیرون از tmux در یک terminal شناور Snacks.

---

# LSP ownership

## Global و همیشه در دسترس

| زبان/format | server/tool |
| :--- | :--- |
| Nix | nixd، Alejandra، Statix، Deadnix |
| Lua | lua-language-server، StyLua |
| Shell | bash-language-server، ShellCheck، shfmt |
| TOML | Taplo |
| YAML | yaml-language-server |
| Markdown | Marksman |
| JSON/Markdown/YAML/JS format | Prettier |

## Project-only

| زبان | devShell | server/debugger |
| :--- | :--- | :--- |
| Python | `dev python` | Pyright، Ruff، debugpy |
| JS/TS/HTML/CSS/JSON | `dev web` | typescript-language-server، vscode-langservers، Tailwind، Emmet، Biome و ESLint (فقط در پروژه‌ای که config آن‌ها را دارد) |
| Rust | `dev rust` | rust-analyzer، lldb-dap |
| Go | `dev go` | gopls، dlv |
| C/C++ | `dev build` | clangd، clang-format، lldb-dap، gdb |

`lua/lsp.lua` هر server را با executable و devShell مربوطه توصیف می‌کند و فقط وقتی `vim.lsp.enable` می‌زند که executable روی PATH باشد. دلیلش این است که lspconfig برای `ts_ls`, `html`, `cssls`, `jsonls`, `tailwindcss` و `yamlls` مقدار `cmd` را function می‌گذارد و Neovim نمی‌تواند وجودش را پیش از اجرا بسنجد؛ enable کورکورانه هر بار باز کردن یک `.json` بیرون از `dev web` را با warning «Spawning language server … failed» همراه می‌کرد. وقتی direnv محیط پروژه را export کرد (`User DirenvLoaded`)، serverهای تازه‌در‌دسترس enable می‌شوند و به bufferهای باز attach می‌شوند.

Biome با `biome.json(c)` و ESLint با `eslint.config.*` یا `.eslintrc*` attach می‌شوند و بیرون از چنین پروژه‌ای هیچ‌کدام راه نمی‌افتند (با Biome 2.4.16 و vscode-langservers-extracted 1.121 آزمایش شد). ESLint کتابخانه‌ی `eslint` را از `node_modules` پروژه می‌خواند؛ پیش از نصب وابستگی‌های پروژه پیام `Unable to find ESLint library` طبیعی است.

## diagnosis

داخل Neovim:

```vim
:DevDoctor
:checkhealth vim.lsp
:lsp restart
```

`:DevDoctor` برای filetype بافر جاری LSP و formatterها را با ✔/✖ نشان می‌دهد و می‌گوید کدام devShell ابزار گم‌شده را دارد. `:LspInfo` و `:LspRestart` دیگر وجود ندارند (lspconfig آن‌ها را وقتی حذف کرد که Neovim خودش `:checkhealth vim.lsp` و `:lsp` را گرفت).

در shell:

```bash
command -v rust-analyzer
command -v gopls
command -v pyright-langserver
```

اگر binary نیست، Neovim را داخل shell مناسب باز کنید یا direnv را فعال کنید.

## actionها

| کلید | عمل |
| :--- | :--- |
| `K` | hover |
| `<leader>lk` | signature help |
| `<leader>lr` | rename symbol |
| `<leader>la` | code action |
| `<leader>li` | `:checkhealth vim.lsp` |
| `<leader>lR` | `:lsp restart` |
| `[d` / `]d` | diagnostic قبلی/بعدی (mapping پیش‌فرض Neovim) |
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
| Python | Ruff organize imports، بعد Ruff format |
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

Autoformat timeout برابر 1200ms و LSP fallback است. C/C++ فقط وقتی روی save format می‌شود که پروژه `.clang-format` داشته باشد (وگرنه clang-format و clangd سبک LLVM را روی هر فایل تحمیل می‌کردند)؛ `<leader>cf` همیشه دستی کار می‌کند. در Go، gopls قبل از save importها را مرتب می‌کند. clangd برای پیدا کردن headerها به `compile_commands.json` نیاز دارد (tip داخل `dev build`). اگر formatter external نیست، ابتدا PATH/project environment را بررسی کنید؛ config را با formatter دوم پنهان نکنید.

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

# اجرا و تست

| کلید | عمل |
| :--- | :--- |
| `<leader>rr` | اجرای فایل جاری |
| `<leader>rt` | تست پروژه |
| `<leader>rR` | تکرار آخرین run/test |

`lua/tasks.lua` برای هر filetype ریشه‌ی پروژه را با markerهایش (`Cargo.toml`، `go.mod`، `pyproject.toml`، `package.json`، …) پیدا می‌کند و دستور را در terminal پایین Snacks اجرا می‌کند؛ فوکوس در editor می‌ماند (`<C-w>j` برای رفتن به خروجی و `i` برای ورودی process، `q` برای پنهان‌کردن) و خروجی بعد از پایان process می‌ماند. در JS/TS ابزار از lockfile انتخاب می‌شود (`bun.lock`، `pnpm-lock.yaml`، `yarn.lock`، وگرنه npm). دستور از PATH همین Neovim می‌آید، پس داخل devShell همان `pytest`/`cargo`/`go` پروژه است؛ اگر ابزار نبود، به‌جای خطای terminal یک پیام می‌گیرید. نکته‌ی Snacks: اگر فوکوس داخل یک terminal Snacks (Lazygit، خروجی run) باشد، اولین `:qa` فقط همان terminal را می‌بندد و باید دوباره زده شود، چون handler مربوط به `ExitPre` پنجره‌ای را که Neovim از آن خارج می‌شد می‌بندد؛ از پنجره‌ی editor اشکالی ندارد.

---

# Python REPL و cell workflow

مارکرهای پشتیبانی‌شده:

```python
# %%
# <codecell>
```

| کلید | عمل |
| :--- | :--- |
| `<leader>rp` | IPython در tmux pane (PATH و `VIRTUAL_ENV` همین Neovim به pane داده می‌شود) |
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
| Python | debugpy | `dev python` (`NVIM_DEBUGPY_PYTHON`) |
| Lua/Neovim | one-small-step-for-vimkind | global plugin (فقط با `:DapLuaServer` load می‌شود) |
| Rust/C/C++/Zig | lldb-dap | `dev rust` / `dev build` |
| C/C++ fallback | GDB DAP | `dev build` |
| Go | Delve | `dev go` |

اگر adapter project-only روی PATH نباشد، config command shell مناسب را در notification نشان می‌دهد.

### چرا debugpy مفسر جدا دارد

`dev python` عمداً `PYTHONPATH` را unset می‌کند تا کتابخانه‌های Nix وارد virtualenv پروژه نشوند. همین باعث می‌شد `python3` خود shell دیگر debugpy را نبیند (`No module named 'debugpy'`) و adapter بالا نیاید. حالا shell متغیر `NVIM_DEBUGPY_PYTHON` را به مفسری که debugpy دارد export می‌کند؛ `dap.lua` آن را هنگام شروع session می‌خواند (نه هنگام startup، چون direnv بعد از Neovim export می‌کند). این مفسر هرگز کد پروژه را اجرا نمی‌کند. کد پروژه با `.venv` خودش اجرا می‌شود.

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

## Rust

پیکربندی اول «Launch (cargo build, lldb)» است: `cargo build` را بدون قفل‌کردن editor اجرا می‌کند، executable را از خروجی JSON خود cargo پیدا می‌کند (چند binary → picker) و بدون تایپ مسیر debug را شروع می‌کند. پیکربندی دوم مسیر executable را دستی می‌پرسد.

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
| `<leader>uu` | undo tree (بومی Neovim 0.12؛ با اولین استفاده load می‌شود) |
| `<leader>uh` | inlay hintهای LSP (پیش‌فرض خاموش) |
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

# `:checkhealth` — کدام هشدارها طبیعی‌اند

بعد از هر تغییر config، `:checkhealth` را بخوانید؛ این موارد عمداً باقی می‌مانند:

| پیام | چرا | اقدام |
| :--- | :--- | :--- |
| `nvim-treesitter`: `tree-sitter-cli not found` و `Install directory … is not writable` | parserها pre-built از Nix می‌آیند و پوشه‌ی نصب فقط‌خواندنی است؛ هر دو فقط برای `:TSInstall` مهم‌اند (CLI حدود 57 MiB است) | هیچ (ADR: «Treesitter را خود Neovim اجرا می‌کند») |
| `conform`: `ruff`/`rustfmt`/`clang_format`/`fish_indent` unavailable | formatter پروژه‌ای است و فقط داخل devShell هست | `dev python` / `dev rust` / `dev build` |
| `Snacks.image`: `gs`، `tectonic`/`pdflatex`، `mmdc` | رندر PDF، فرمول LaTeX و Mermaid اختیاری است و سنگین (Mermaid یک Chromium می‌خواهد) | فقط اگر واقعاً لازم شد، در یک devShell |
| `diffview`: `hg_cmd` is not executable | Mercurial نصب نیست و Git کافی است | هیچ |
| `vim.health`: `Nvim 0.12.x is available` | `flake.lock` عمداً pin شده است | وقتی آماده‌ی آپدیت بودید: `nix flake update nixpkgs` |

هر ERROR یا WARNING دیگری را جدی بگیرید. اگر cache بایت‌کد خراب به نظر رسید: `:lua vim.loader.reset()`.

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
