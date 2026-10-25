-- Formatting via conform.nvim.
-- Linting is handled by LSP servers (ruff, shellcheck, statix, deadnix, etc.)
local ok_conform, conform = pcall(require, "conform")
if ok_conform then
	conform.setup({
		formatters_by_ft = {
			-- Imports first, then format: Ruff documents this order, and the reverse can leave
			-- the sorted import block unformatted.
			python = { "ruff_organize_imports", "ruff_format" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },
			rust = { "rustfmt" },
			lua = { "stylua" },
			nix = { "alejandra" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
			fish = { "fish_indent" },
			json = { "prettier" },
			jsonc = { "prettier" },
			css = { "prettier" },
			scss = { "prettier" },
			html = { "prettier" },
			markdown = { "prettier" },
			yaml = { "prettier" },
			toml = { "taplo" },
			c = { "clang_format" },
			cpp = { "clang_format" },
		},
		formatters = {
			-- clang-format and clangd both fall back to the LLVM style, which would be
			-- imposed on every C/C++ file of a project that has no .clang-format.
			clang_format = {
				condition = function(_, ctx)
					return vim.fs.root(ctx.dirname, { ".clang-format", "_clang-format" }) ~= nil
				end,
			},
		},
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return nil
			end
			local ft = vim.bo[bufnr].filetype
			if (ft == "c" or ft == "cpp") and not vim.fs.root(bufnr, { ".clang-format", "_clang-format" }) then
				return nil -- format C/C++ on save only where the project defines its style
			end
			return { timeout_ms = 1200, lsp_format = "fallback" }
		end,
	})

	-- Manual format on demand
	vim.keymap.set({ "n", "v" }, "<leader>cf", function()
		conform.format({ async = true, lsp_format = "fallback" })
	end, { desc = "Format file or selection" })

	-- Toggle autoformat for CURRENT BUFFER only
	vim.keymap.set("n", "<leader>uf", function()
		vim.b.disable_autoformat = not vim.b.disable_autoformat
		local state = vim.b.disable_autoformat and "OFF (buffer)" or "ON (buffer)"
		vim.notify("Autoformat: " .. state, vim.log.levels.INFO, { title = "Conform" })
	end, { desc = "Toggle autoformat (current buffer)" })

	-- Toggle autoformat GLOBALLY
	vim.keymap.set("n", "<leader>uF", function()
		vim.g.disable_autoformat = not vim.g.disable_autoformat
		local state = vim.g.disable_autoformat and "OFF (global)" or "ON (global)"
		vim.notify("Autoformat: " .. state, vim.log.levels.INFO, { title = "Conform" })
	end, { desc = "Toggle autoformat (global)" })
end
