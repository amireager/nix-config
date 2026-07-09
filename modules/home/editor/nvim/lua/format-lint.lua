-- Formatting and linting. Tools are installed by Nix in default.nix.
local ok_conform, conform = pcall(require, "conform")
if ok_conform then
  conform.setup({
    formatters_by_ft = {
      python = { "ruff_format", "ruff_organize_imports" },
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
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return nil
      end
      return { timeout_ms = 1200, lsp_fallback = true }
    end,
  })

  vim.keymap.set({ "n", "v" }, "<leader>cf", function()
    conform.format({ async = true, lsp_fallback = true })
  end, { desc = "Format file or selection" })

  vim.keymap.set("n", "<leader>cF", function()
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("Autoformat: " .. (vim.g.disable_autoformat and "off" or "on"))
  end, { desc = "Toggle autoformat" })
end

local ok_lint, lint = pcall(require, "lint")
if ok_lint then
  lint.linters_by_ft = {
    python = { "ruff" },
    nix = { "statix", "deadnix" },
    sh = { "shellcheck" },
    bash = { "shellcheck" },
  }

  local lint_group = vim.api.nvim_create_augroup("UserLint", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
    group = lint_group,
    callback = function()
      lint.try_lint()
    end,
  })

  vim.keymap.set("n", "<leader>cl", function()
    lint.try_lint()
  end, { desc = "Run linter" })
end
