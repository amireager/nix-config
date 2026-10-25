-- Native Neovim 0.12 LSP setup.
--
-- One table describes every server: the executable it needs (`bin`) and the dev
-- shell that provides it (`shell`; nil = always installed with Neovim). A server
-- is only *enabled* when its executable exists. That matters: lspconfig defines
-- `cmd` as a *function* for ts_ls, html, cssls, jsonls, tailwindcss, yamlls,
-- eslint and biome, and Neovim cannot probe a function — enabling those blindly
-- makes every matching file print "Spawning language server ... failed" whenever
-- you are outside the dev shell.
--
-- direnv.vim exports a project's environment asynchronously (VimEnter and
-- DirChanged) and announces it with `User DirenvLoaded`. Servers that have
-- become available are enabled then, and Neovim attaches them to buffers that
-- are already open.

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
	capabilities = blink.get_lsp_capabilities(capabilities)
end
vim.lsp.config("*", { capabilities = capabilities })

-- Diagnostics. Since Nvim 0.12 signs can only be configured here:
-- `sign_define("DiagnosticSignError", ...)` is ignored, which is why the sign
-- column used to show the default E/W/I/H letters.
local severity = vim.diagnostic.severity
vim.diagnostic.config({
	virtual_text = { spacing = 4, prefix = "●" },
	signs = {
		text = {
			[severity.ERROR] = "\u{f057} ",
			[severity.WARN] = "\u{f071} ",
			[severity.INFO] = "\u{f05a} ",
			[severity.HINT] = "\u{f0eb} ",
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
})

-- name = lspconfig server name. Everything except `bin` and `shell` is passed
-- to vim.lsp.config().
local servers = {
	-- Always installed with Neovim (home-manager `extraPackages`).
	nixd = {
		bin = "nixd",
		settings = { nixd = { formatting = { command = { "alejandra" } } } },
	},
	lua_ls = {
		bin = "lua-language-server",
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				workspace = { checkThirdParty = false },
				telemetry = { enable = false },
			},
		},
	},
	bashls = { bin = "bash-language-server" },
	taplo = { bin = "taplo" },
	yamlls = { bin = "yaml-language-server" },
	marksman = { bin = "marksman" },

	-- Project tools, from the matching dev shell.
	pyright = {
		bin = "pyright-langserver",
		shell = "python",
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					-- "workspace" analyses every file in the project on each
					-- change and floods Trouble with diagnostics from files you
					-- never opened. Use `pyright` (or Trouble) for a full sweep.
					diagnosticMode = "openFilesOnly",
				},
			},
		},
	},
	ruff = { bin = "ruff", shell = "python" },
	ts_ls = { bin = "typescript-language-server", shell = "web" },
	-- Both attach only in projects that have a Biome / ESLint configuration.
	biome = { bin = "biome", shell = "web" },
	eslint = { bin = "vscode-eslint-language-server", shell = "web" },
	html = { bin = "vscode-html-language-server", shell = "web" },
	cssls = { bin = "vscode-css-language-server", shell = "web" },
	jsonls = { bin = "vscode-json-language-server", shell = "web" },
	tailwindcss = { bin = "tailwindcss-language-server", shell = "web" },
	emmet_language_server = { bin = "emmet-language-server", shell = "web" },
	rust_analyzer = {
		bin = "rust-analyzer",
		shell = "rust",
		settings = {
			["rust-analyzer"] = {
				checkOnSave = { command = "clippy" },
				cargo = { allFeatures = true },
			},
		},
	},
	gopls = { bin = "gopls", shell = "go" },
	clangd = {
		bin = "clangd",
		shell = "build",
		-- It finds headers through compile_commands.json: see the `dev build` tip.
		cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
	},
}

for name, spec in pairs(servers) do
	local config = vim.deepcopy(spec)
	config.bin, config.shell = nil, nil
	local ok, err = pcall(vim.lsp.config, name, config)
	if not ok then
		vim.notify("Failed to configure LSP server " .. name .. ": " .. tostring(err), vim.log.levels.WARN)
	end
end

local function enable_available()
	local names = {}
	for name, spec in pairs(servers) do
		if vim.fn.executable(spec.bin) == 1 then
			names[#names + 1] = name
		end
	end
	if #names > 0 then
		vim.lsp.enable(names)
	end
end

enable_available()

vim.api.nvim_create_autocmd("User", {
	group = vim.api.nvim_create_augroup("UserLspDirenv", { clear = true }),
	pattern = "DirenvLoaded",
	desc = "Enable LSP servers that the project environment just made available",
	callback = enable_available,
})

-- Keymaps. Defaults from Neovim 0.11+ are left alone: `]d`/`[d` (diagnostics),
-- `grr`/`gra`/`grn`/`gri`/`grt`/`gO`, `<C-W>d` and `<C-S>` in insert mode.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end
		local buf = args.buf
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
		end

		-- gopls does not sort imports when it formats; the editor has to ask for it.
		if client.name == "gopls" and not vim.b[buf].gopls_organize_imports then
			vim.b[buf].gopls_organize_imports = true
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = buf,
				desc = "gopls: organize imports before save",
				callback = function()
					local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
					params.context = { only = { "source.organizeImports" }, diagnostics = {} }
					local response = client:request_sync("textDocument/codeAction", params, 1000, buf)
					for _, action in ipairs(response and response.result or {}) do
						if action.edit then
							vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
						end
						if action.command then
							client:exec_cmd(action.command, { bufnr = buf })
						end
					end
				end,
			})
		end

		-- Ruff only lints and formats. Its hover repeats Pyright's, so every K
		-- showed two windows.
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end

		if client:supports_method("textDocument/hover", buf) then
			map("n", "K", vim.lsp.buf.hover, "Hover documentation")
		end
		if client:supports_method("textDocument/signatureHelp", buf) then
			map("n", "<leader>lk", vim.lsp.buf.signature_help, "Signature help")
		end
		if client:supports_method("textDocument/rename", buf) then
			map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
		end
		if client:supports_method("textDocument/codeAction", buf) then
			map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
		end
		if client:supports_method("textDocument/formatting", buf) then
			map("n", "<leader>lf", function()
				vim.lsp.buf.format({ async = true })
			end, "Format buffer (LSP only)")
		end

		-- `:LspInfo` and `:LspRestart` no longer exist (lspconfig dropped them
		-- when Neovim gained `:checkhealth vim.lsp` and `:lsp`).
		map("n", "<leader>li", "<cmd>checkhealth vim.lsp<CR>", "LSP health and attached features")
		map("n", "<leader>lR", "<cmd>lsp restart<CR>", "Restart LSP clients")
		map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
		map("n", "<leader>lq", vim.diagnostic.setqflist, "Diagnostics to quickfix")
	end,
})

-- :DevDoctor — why is there no LSP / formatter here? Lists the language tools
-- for the current filetype and the dev shell that provides each missing one.
vim.api.nvim_create_user_command("DevDoctor", function()
	local ft = vim.bo.filetype
	local lines = { ("Language tools for filetype %q"):format(ft) }
	local found = false

	for name, spec in vim.spairs(servers) do
		local config = vim.lsp.config[name]
		if config and config.filetypes and vim.list_contains(config.filetypes, ft) then
			found = true
			local ok = vim.fn.executable(spec.bin) == 1
			local hint = ok and spec.bin or (spec.bin .. (spec.shell and ("  →  dev " .. spec.shell) or ""))
			lines[#lines + 1] = ("  LSP     %-22s %s %s"):format(name, ok and "✔" or "✖", hint)
		end
	end

	local ok_conform, conform = pcall(require, "conform")
	if ok_conform then
		for _, info in ipairs(conform.list_formatters(0)) do
			found = true
			lines[#lines + 1] = ("  format  %-22s %s %s"):format(
				info.name,
				info.available and "✔" or "✖",
				info.available and info.command or (info.available_msg or info.command)
			)
		end
	end

	if not found then
		lines[#lines + 1] = "  nothing configured for this filetype"
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "DevDoctor" })
end, { desc = "Show which language tools exist for this buffer and which dev shell provides them" })
