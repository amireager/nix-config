-- ============================================================================
-- DAP — Debug Adapter Protocol
-- ============================================================================
-- This does not replace the `#%%` + IPython flow in run.lua. They answer
-- different questions:
--
--   #%%   what does this data look like?   you send blocks, it evaluates
--   DAP   why is this code wrong?          it runs, stops, shows state
--
-- The capability with no print-statement equivalent is the conditional
-- breakpoint: in a ten-thousand-iteration loop, `item.id == 47` stops exactly
-- once, with the call stack and every variable in scope intact.
-- ============================================================================

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
	return
end

-- ── Signs ───────────────────────────────────────────────────────────────────
for name, opts in pairs({
	DapBreakpoint = { text = "●", texthl = "DiagnosticSignError" },
	DapBreakpointCondition = { text = "◆", texthl = "DiagnosticSignWarn" },
	DapLogPoint = { text = "◈", texthl = "DiagnosticSignInfo" },
	DapStopped = { text = "▶", texthl = "DiagnosticSignWarn", linehl = "Visual" },
	DapBreakpointRejected = { text = "○", texthl = "DiagnosticSignHint" },
}) do
	vim.fn.sign_define(name, opts)
end

-- ── Adapters ────────────────────────────────────────────────────────────────

-- Python. `dev python` unsets PYTHONPATH so Nix libraries never leak into
-- project virtualenvs, and that also hides `python3Packages.debugpy` from the
-- shell's own `python3`: `python3 -m debugpy.adapter` died with "No module named
-- debugpy". The shell therefore exports NVIM_DEBUGPY_PYTHON, an interpreter that
-- carries debugpy and is reached by absolute path, never touching the project's
-- environment. direnv exports it *after* Neovim has started, so it is read when
-- a session starts, not here. (This does not need Neovim's Python provider.)
local ok_py, dap_python = pcall(require, "dap-python")
if ok_py then
	dap_python.setup("python3") -- also registers the launch configurations
	dap_python.test_runner = "pytest"

	local adapter_for, inner
	local function python_adapter(callback, config)
		local py = vim.env.NVIM_DEBUGPY_PYTHON
		if not py or py == "" then
			py = "python3"
		end
		if py ~= adapter_for then
			-- setup() installs a fresh adapter under the same key (and would repeat
			-- the configurations); keep that adapter and put this resolver back.
			dap_python.setup(py, { include_configs = false })
			inner, adapter_for = dap.adapters.python, py
			dap.adapters.python, dap.adapters.debugpy = python_adapter, python_adapter
		end
		return inner(callback, config)
	end
	dap.adapters.python, dap.adapters.debugpy = python_adapter, python_adapter
end

-- Adapters for compiled languages are NOT installed alongside Neovim: lldb
-- pulls libclang and the pair costs ~849 MiB, which does not belong in a
-- global closure for a tool used per-project. They come from `dev build`,
-- `dev rust` and `dev go`, and direnv-vim attaches them on entering the
-- project — the same path rust-analyzer and gopls already take.
--
-- Missing adapters are therefore normal, not a fault. This reports which
-- shell provides the one you asked for instead of failing with ENOENT.
local shell_for = {
	["lldb-dap"] = "dev build   (or dev rust)",
	["gdb"] = "dev build",
	["dlv"] = "dev go",
}

local function adapter(cmd, spec)
	return function(callback, config)
		if vim.fn.executable(cmd) == 0 then
			vim.notify(
				("%s is not on PATH.\nStart Neovim inside: %s"):format(cmd, shell_for[cmd] or "the matching dev shell"),
				vim.log.levels.WARN,
				{ title = "DAP" }
			)
			return
		end
		if type(spec) == "function" then
			return spec(callback, config)
		end
		callback(spec)
	end
end

-- lldb-dap ships with lldb itself, so C/C++/Rust/Zig need no extension.
dap.adapters.lldb = adapter("lldb-dap", {
	type = "executable",
	command = "lldb-dap",
	name = "lldb",
})

dap.adapters.gdb = adapter("gdb", {
	type = "executable",
	command = "gdb",
	args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
})

-- Go. delve comes from `dev go`.
dap.adapters.delve = adapter("dlv", function(callback, config)
	if config.mode == "remote" and config.request == "attach" then
		callback({
			type = "server",
			host = config.host or "127.0.0.1",
			port = config.port or 38697,
		})
	else
		callback({
			type = "server",
			port = "${port}",
			executable = {
				command = "dlv",
				args = { "dap", "-l", "127.0.0.1:${port}" },
			},
		})
	end
end)

-- ── Configurations ──────────────────────────────────────────────────────────

local lldb_launch = {
	name = "Launch (lldb)",
	type = "lldb",
	request = "launch",
	program = function()
		return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
	end,
	cwd = "${workspaceFolder}",
	stopOnEntry = false,
	args = function()
		return vim.split(vim.fn.input("Arguments: "), " ", { trimempty = true })
	end,
}

dap.configurations.c = { lldb_launch }
dap.configurations.cpp = { lldb_launch }
dap.configurations.zig = { lldb_launch }

-- Rust: build with cargo, then find the executable in cargo's own JSON output
-- instead of asking you to type target/debug/<name>. A package with several
-- binary targets gets a picker. nvim-dap resumes a returned coroutine with the
-- value, so the build does not freeze the editor.
local function cargo_program()
	return coroutine.create(function(dap_run_co)
		local function finish(value)
			vim.schedule(function()
				coroutine.resume(dap_run_co, value)
			end)
		end

		if vim.fn.executable("cargo") ~= 1 then
			vim.notify("cargo is not on PATH.\nStart Neovim inside: dev rust", vim.log.levels.WARN, { title = "DAP" })
			return finish(dap.ABORT)
		end
		local root = vim.fs.root(0, "Cargo.toml") or vim.fn.getcwd()
		vim.notify("cargo build …", vim.log.levels.INFO, { title = "DAP" })
		vim.system({ "cargo", "build", "--message-format=json-render-diagnostics" }, {
			cwd = root,
			text = true,
		}, function(result)
			if result.code ~= 0 then
				vim.schedule(function()
					local tail = vim.list_slice(vim.split(result.stderr or "", "\n", { trimempty = true }), -12)
					vim.notify(
						"cargo build failed\n" .. table.concat(tail, "\n"),
						vim.log.levels.ERROR,
						{ title = "DAP" }
					)
				end)
				return finish(dap.ABORT)
			end
			local binaries = {}
			for line in (result.stdout or ""):gmatch("[^\n]+") do
				local decoded, message = pcall(vim.json.decode, line)
				if
					decoded
					and type(message) == "table"
					and message.reason == "compiler-artifact"
					and message.executable
					and vim.list_contains(message.target.kind, "bin")
				then
					binaries[#binaries + 1] = message.executable
				end
			end
			if #binaries == 0 then
				vim.schedule(function()
					vim.notify("cargo built no binary target", vim.log.levels.WARN, { title = "DAP" })
				end)
				return finish(dap.ABORT)
			end
			if #binaries == 1 then
				return finish(binaries[1])
			end
			table.sort(binaries) -- cargo reports artifacts in completion order
			vim.schedule(function()
				vim.ui.select(binaries, { prompt = "Debug binary:", format_item = vim.fs.basename }, function(choice)
					finish(choice or dap.ABORT)
				end)
			end)
		end)
	end)
end

-- Rust also needs the compiler's pretty-printers loaded, otherwise Vec and
-- String display as raw pointers rather than their contents.
local function rust_pretty_printers()
	local sysroot = vim.fn.trim(vim.fn.system("rustc --print sysroot"))
	local etc = sysroot .. "/lib/rustlib/etc"
	return {
		'command script import "' .. etc .. '/lldb_lookup.py"',
		'command source -s 0 "' .. etc .. '/lldb_commands"',
	}
end

dap.configurations.rust = {
	vim.tbl_extend("force", lldb_launch, {
		name = "Launch (cargo build, lldb)",
		program = cargo_program,
		initCommands = rust_pretty_printers,
	}),
	vim.tbl_extend("force", lldb_launch, {
		name = "Launch executable (lldb, rust)",
		initCommands = rust_pretty_printers,
	}),
}

dap.configurations.go = {
	{ type = "delve", name = "Debug this file", request = "launch", program = "${file}" },
	{ type = "delve", name = "Debug this package", request = "launch", program = "./${relativeFileDirname}" },
	{ type = "delve", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
}

-- Debugging this configuration. Run :DapLuaServer in the instance you want to
-- inspect, then attach from a second Neovim. one-small-step-for-vimkind is only
-- required when that command runs, so it is not loaded at startup.
dap.adapters.nlua = function(callback, config)
	callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
end
dap.configurations.lua = {
	{ type = "nlua", request = "attach", name = "Attach to running Neovim" },
}
vim.api.nvim_create_user_command("DapLuaServer", function()
	local ok, osv = pcall(require, "osv")
	if not ok then
		vim.notify("one-small-step-for-vimkind is not installed", vim.log.levels.WARN, { title = "DAP" })
		return
	end
	osv.launch({ port = 8086 })
end, { desc = "Start the Lua debug server in this instance" })

-- ── UI ──────────────────────────────────────────────────────────────────────
local ok_ui, dapui = pcall(require, "dapui")
if ok_ui then
	dapui.setup({
		icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
		layouts = {
			{
				elements = {
					{ id = "scopes", size = 0.35 }, -- variables in scope: the main view
					{ id = "breakpoints", size = 0.2 },
					{ id = "stacks", size = 0.25 },
					{ id = "watches", size = 0.2 },
				},
				size = 44,
				position = "left",
			},
			{
				elements = {
					{ id = "repl", size = 0.5 }, -- evaluate anything at the stop point
					{ id = "console", size = 0.5 },
				},
				size = 0.28,
				position = "bottom",
			},
		},
		floating = { border = "rounded", mappings = { close = { "q", "<Esc>" } } },
	})

	-- Panels appear with the session and disappear with it, so the editor is
	-- not permanently split.
	dap.listeners.after.event_initialized["dapui"] = function()
		dapui.open({})
	end
	dap.listeners.before.event_terminated["dapui"] = function()
		dapui.close({})
	end
	dap.listeners.before.event_exited["dapui"] = function()
		dapui.close({})
	end
end

local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
if ok_vt then
	vt.setup({
		enabled = true,
		commented = false,
		virt_text_pos = "eol",
		only_first_definition = true,
		all_references = false,
	})
end

-- ── Keymaps ─────────────────────────────────────────────────────────────────
local map = vim.keymap.set

map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Breakpoint: toggle" })

map("n", "<leader>dB", function()
	vim.ui.input({ prompt = "Break when: " }, function(cond)
		if cond and cond ~= "" then
			dap.set_breakpoint(cond)
		end
	end)
end, { desc = "Breakpoint: conditional" })

map("n", "<leader>dl", function()
	vim.ui.input({ prompt = "Log message: " }, function(msg)
		if msg and msg ~= "" then
			dap.set_breakpoint(nil, nil, msg)
		end
	end)
end, { desc = "Breakpoint: log point (no stop)" })

map("n", "<leader>dc", dap.continue, { desc = "Continue / start" })
map("n", "<leader>dC", dap.run_to_cursor, { desc = "Run to cursor" })
map("n", "<leader>do", dap.step_over, { desc = "Step over" })
map("n", "<leader>di", dap.step_into, { desc = "Step into" })
map("n", "<leader>dO", dap.step_out, { desc = "Step out" })
map("n", "<leader>dr", dap.restart, { desc = "Restart session" })
map("n", "<leader>dq", dap.terminate, { desc = "Terminate session" })
map("n", "<leader>dR", dap.repl.toggle, { desc = "REPL toggle" })
map("n", "<leader>dj", dap.down, { desc = "Stack: down a frame" })
map("n", "<leader>dk", dap.up, { desc = "Stack: up a frame" })

map("n", "<leader>dX", function()
	dap.clear_breakpoints()
	vim.notify("All breakpoints cleared", vim.log.levels.INFO, { title = "DAP" })
end, { desc = "Breakpoints: clear all" })

if ok_ui then
	map("n", "<leader>du", function()
		require("dapui").toggle({})
	end, { desc = "UI toggle" })

	map({ "n", "v" }, "<leader>de", function()
		require("dapui").eval(nil, { enter = true })
	end, { desc = "Evaluate expression" })
end

if ok_py then
	map("n", "<leader>dt", function()
		require("dap-python").test_method()
	end, { desc = "Python: debug test under cursor" })
	map("n", "<leader>dT", function()
		require("dap-python").test_class()
	end, { desc = "Python: debug test class" })
	map("v", "<leader>ds", function()
		require("dap-python").debug_selection()
	end, { desc = "Python: debug selection" })
end

-- ── Persistence ─────────────────────────────────────────────────────────────
-- Losing a carefully placed set of breakpoints to a restart is the main reason
-- people stop using a debugger, so they are saved and restored.
local ok_bp, breakpoints = pcall(require, "dap.breakpoints")
if ok_bp then
	local store = vim.fn.stdpath("state") .. "/dap-breakpoints.json"

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			local out = {}
			for buf, bps in pairs(breakpoints.get()) do
				local name = vim.api.nvim_buf_get_name(buf)
				if name ~= "" then
					out[name] = bps
				end
			end
			pcall(vim.fn.writefile, { vim.json.encode(out) }, store)
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = vim.schedule_wrap(function()
			if vim.fn.filereadable(store) == 0 then
				return
			end
			local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(store), "\n"))
			if not ok or type(data) ~= "table" then
				return
			end
			for name, bps in pairs(data) do
				if vim.fn.filereadable(name) == 1 then
					local buf = vim.fn.bufadd(name)
					vim.fn.bufload(buf)
					for _, bp in ipairs(bps) do
						pcall(breakpoints.set, {
							condition = bp.condition,
							log_message = bp.logMessage,
						}, buf, bp.line)
					end
				end
			end
		end),
	})
end
