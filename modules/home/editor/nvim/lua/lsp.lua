-- Native Neovim 0.11+ LSP setup.
-- nvim-lspconfig is still used as a source of server definitions, but not as the deprecated framework.

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.diagnostic.config({
	virtual_text = { spacing = 4, prefix = "●" },
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
})

local signs = {
	Error = " ",
	Warn = " ",
	Hint = " ",
	Info = " ",
}

for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local function on_attach(_, bufnr)
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
	map("n", "gr", vim.lsp.buf.references, "Go to references")
	map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
	map("n", "K", vim.lsp.buf.hover, "Hover documentation")
	map("n", "<leader>lk", vim.lsp.buf.signature_help, "Signature help")
	map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
	map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code action")
	map("n", "<leader>lf", function()
		vim.lsp.buf.format({ async = true })
	end, "LSP format")
	map("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP info")

	map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
	map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
	map("n", "<leader>dd", vim.diagnostic.open_float, "Line diagnostics")
	map("n", "<leader>dq", vim.diagnostic.setqflist, "Diagnostics to quickfix")
end

local servers = {
	pyright = {
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "workspace",
				},
			},
		},
	},

	ruff = {},

	ts_ls = {},

	rust_analyzer = {
		settings = {
			["rust-analyzer"] = {
				cargo = { allFeatures = true },
				check = { command = "clippy" },
				procMacro = { enable = true },
			},
		},
	},

	html = {},
	cssls = {},
	jsonls = {},
	tailwindcss = {},
	emmet_language_server = {},

	nixd = {
		settings = {
			nixd = {
				formatting = { command = { "alejandra" } },
			},
		},
	},

	lua_ls = {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				workspace = { checkThirdParty = false },
				telemetry = { enable = false },
			},
		},
	},

	bashls = {},
	taplo = {},
	yamlls = {},
	marksman = {},
}

for name, config in pairs(servers) do
	config.capabilities = capabilities
	config.on_attach = on_attach

	local ok_config, config_err = pcall(vim.lsp.config, name, config)
	if ok_config then
		local ok_enable, enable_err = pcall(vim.lsp.enable, name)
		if not ok_enable then
			vim.notify("Failed to enable LSP server " .. name .. ": " .. tostring(enable_err), vim.log.levels.WARN)
		end
	else
		vim.notify("Failed to configure LSP server " .. name .. ": " .. tostring(config_err), vim.log.levels.WARN)
	end
end
