-- DAP (Debug Adapter Protocol) — debugging support
-- Currently disabled — codeberg.org blocked in Iran (TLS error)
-- Uncomment plugins in default.nix and restore this file after first build with proxy

-- Placeholder keymaps (will be replaced when DAP is enabled)
vim.keymap.set("n", "<leader>db", function()
  vim.notify("DAP not installed — uncomment plugins in default.nix", vim.log.levels.WARN)
end, { desc = "Toggle breakpoint (DAP disabled)" })

vim.keymap.set("n", "<leader>dc", function()
  vim.notify("DAP not installed — uncomment plugins in default.nix", vim.log.levels.WARN)
end, { desc = "Continue (DAP disabled)" })
