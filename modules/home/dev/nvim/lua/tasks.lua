-- Run and test from the editor, under <leader>r next to the Python REPL.
--
--   <leader>rr  run the current file (Python, Rust, Go, JS/TS, Lua, shell)
--   <leader>rt  run the project's tests
--   <leader>rR  repeat the last run/test
--
-- Output goes to a Snacks terminal at the bottom and stays after the process
-- ends (q hides it). Focus stays in the editor: <C-w>j reaches the output, and
-- a :qa typed inside a Snacks terminal only closes that terminal first (its
-- ExitPre handler closes the window Neovim was quitting from). Commands come
-- from the PATH Neovim sees, so inside a dev shell they are the project's own
-- pytest, cargo, go, bun, ...; a missing tool is reported instead of failing
-- inside the terminal.
local ok, snacks = pcall(require, "snacks")
if not ok then
	return
end

local function executable(bin)
	return vim.fn.executable(bin) == 1
end

local function exists(dir, name)
	return vim.uv.fs_stat(dir .. "/" .. name) ~= nil
end

-- JS/TS projects use whichever package manager left a lockfile.
local function node_tool(dir)
	if exists(dir, "bun.lock") or exists(dir, "bun.lockb") then
		return "bun"
	end
	if exists(dir, "pnpm-lock.yaml") then
		return "pnpm"
	end
	if exists(dir, "yarn.lock") then
		return "yarn"
	end
	return "npm"
end

-- Per filetype: the markers that locate the project root, what `run` executes
-- for the current file and what `test` executes for the project. Both return
-- an argv list.
local runners = {
	python = {
		root = { "pyproject.toml", "pytest.ini", "setup.cfg", ".git" },
		run = function(file)
			return { "python3", file }
		end,
		test = function()
			return executable("pytest") and { "pytest", "-q" } or { "python3", "-m", "pytest", "-q" }
		end,
	},
	rust = {
		root = { "Cargo.toml" },
		run = function()
			return { "cargo", "run" }
		end,
		test = function()
			return executable("cargo-nextest") and { "cargo", "nextest", "run" } or { "cargo", "test" }
		end,
	},
	go = {
		root = { "go.mod" },
		in_file_dir = true, -- `go run .` runs the package in the working directory
		run = function()
			return { "go", "run", "." }
		end,
		test = function()
			if executable("gotestsum") then
				return { "gotestsum", "--format", "testname", "./..." }
			end
			return { "go", "test", "./..." }
		end,
	},
	lua = {
		root = { ".git" },
		run = function(file)
			return { "nvim", "-l", file }
		end,
	},
}

local javascript = {
	root = { "package.json" },
	run = function(file)
		return { executable("bun") and "bun" or "node", file }
	end,
	test = function(dir)
		return { node_tool(dir), "test" }
	end,
}
for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
	runners[ft] = javascript
end

for ft, shell in pairs({ sh = "bash", bash = "bash", fish = "fish" }) do
	runners[ft] = {
		root = { ".git" },
		run = function(file)
			return { shell, file }
		end,
	}
end

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.WARN, { title = "Run" })
end

local current ---@type snacks.win?
local last ---@type { argv: string[], cwd: string }?

local function launch(argv, cwd)
	if not executable(argv[1]) then
		notify(("`%s` is not on PATH. Open Neovim inside the project's dev shell (:DevDoctor)."):format(argv[1]))
		return
	end
	last = { argv = argv, cwd = cwd }
	if current and current:buf_valid() then
		current:close() -- one task terminal; a re-run replaces the previous output
	end
	local label = (table.concat(argv, " "):gsub("%%", "%%%%"))
	current = snacks.terminal.open(argv, {
		cwd = cwd,
		interactive = false, -- do not auto-close: the output is the point
		win = { position = "bottom", height = 0.35, enter = false, wo = { winbar = "▶ " .. label } },
	})
end

---@param kind "run"|"test"
local function resolve(kind)
	local ft = vim.bo.filetype
	local runner = runners[ft]
	if not (runner and runner[kind]) then
		notify(("No %s command for filetype %q."):format(kind, ft))
		return
	end
	return runner, vim.fs.root(0, runner.root) or vim.fn.getcwd()
end

vim.keymap.set("n", "<leader>rr", function()
	local runner, root = resolve("run")
	if not runner then
		return
	end
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" or vim.bo.buftype ~= "" then
		return notify("Save the buffer to a file first.") -- scratch, terminal and plugin buffers have no file
	end
	vim.cmd("silent update") -- run what is on screen
	launch(runner.run(file, root), runner.in_file_dir and vim.fs.dirname(file) or root)
end, { desc = "Run current file" })

vim.keymap.set("n", "<leader>rt", function()
	local runner, root = resolve("test")
	if not runner then
		return
	end
	vim.cmd("silent! wall")
	launch(runner.test(root), root)
end, { desc = "Run project tests" })

vim.keymap.set("n", "<leader>rR", function()
	if not last then
		return notify("Nothing to repeat yet.", vim.log.levels.INFO)
	end
	vim.cmd("silent! wall")
	launch(last.argv, last.cwd)
end, { desc = "Repeat last run/test" })
