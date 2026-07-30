-- ============================================================================
-- AI — CodeCompanion, and nothing else
-- ============================================================================
-- One plugin. It answers when asked and is silent otherwise: no request is
-- made until a <leader>a key is pressed, and there is no as-you-type
-- completion here at all. That is a decision, not an omission — completion
-- fires on every pause, and on this connection a pause that has to wait for
-- the network is worse than no suggestion.
--
-- ── Where the key lives: nowhere ────────────────────────────────────────────
-- Everything goes to http://127.0.0.1:20128/v1 — the 9router gateway from
-- aihub. Provider keys are typed into that dashboard and stored in
-- aihub/private/, which is gitignored and outside this repository.
--
-- So: no key in this file, none in the Nix store, none in the environment.
-- Changing model or provider happens in the dashboard, with no rebuild.
--
--     cd ~/dev/aihub && hub start 9router
-- ============================================================================

local ok_cc, codecompanion = pcall(require, "codecompanion")
if not ok_cc then
	return
end

local GATEWAY = vim.env.AI_GATEWAY or "http://127.0.0.1:20128"

-- The gateway does check keys, but ours is local and unauthenticated. A
-- literal rather than an empty string: some adapters read an empty key as
-- "not configured" and refuse to start.
local GATEWAY_KEY = vim.env.AI_GATEWAY_KEY or "local"

-- Empty means "let the adapter ask the gateway what it serves and take the
-- first". The gateway's own routing is the thing that should decide, and `ga`
-- inside the chat buffer switches model at runtime — so a list of model names
-- baked in here would only ever be a second list to forget to update.
local MODEL = vim.env.AI_MODEL or ""

-- ── Reachability, checked before the request ────────────────────────────────
-- Without this a down gateway is a curl error from somewhere inside the plugin
-- thirty seconds later. This answers in half a second and says what to run.
local function gateway_up()
	local host = GATEWAY:match("//([^:/]+)") or "127.0.0.1"
	-- Port by scheme, not a flat 80: an https AI_GATEWAY with no explicit port
	-- would otherwise be probed on the wrong one and always look down.
	local port = GATEWAY:match("//[^:/]+:(%d+)")
	if not port then
		port = GATEWAY:match("^https:") and "443" or "80"
	end
	vim.fn.system({ "timeout", "0.5", "bash", "-c", ("exec 3<>/dev/tcp/%s/%s"):format(host, port) })
	return vim.v.shell_error == 0
end

local function require_gateway()
	if gateway_up() then
		return true
	end
	vim.notify(
		("AI gateway unreachable at %s\n  cd ~/dev/aihub && hub start 9router"):format(GATEWAY),
		vim.log.levels.WARN,
		{ title = "CodeCompanion" }
	)
	return false
end

-- ============================================================================
-- Setup
-- ============================================================================
codecompanion.setup({
	adapters = {
		http = {
			-- Named `gateway`, not after a provider: which provider answers is
			-- the gateway's decision, not this file's.
			gateway = function()
				local schema = {}
				if MODEL ~= "" then
					schema.model = { default = MODEL }
				end
				return require("codecompanion.adapters").extend("openai_compatible", {
					env = {
						url = GATEWAY,
						api_key = GATEWAY_KEY,
						chat_url = "/v1/chat/completions",
						models_endpoint = "/v1/models",
					},
					schema = schema,
				})
			end,
		},
	},

	interactions = {
		chat = {
			adapter = "gateway",
			tools = {
				opts = {
					-- Every tool that touches the disk or the shell asks first.
					-- This is the real working directory, not the nix-agent
					-- sandbox, so the prompts are the only thing between the
					-- model and the repository.
					auto_submit_errors = true,
					auto_submit_success = true,
				},
			},
		},
		inline = { adapter = "gateway" },
		cmd = { adapter = "gateway" },
	},

	display = {
		chat = {
			-- Vertical split, not a float: a float over the code under
			-- discussion hides the thing being discussed.
			window = { layout = "vertical", width = 0.42 },

			-- false, and this is not cosmetic. `ga` refuses to run while
			-- show_settings is true — the settings block at the top of the
			-- buffer IS the editable copy of them, so a picker writing the
			-- same values from the other side would be a second source of
			-- truth. Picking the model matters more here than reading it,
			-- because which provider answers changes with what has capacity.
			show_settings = false,

			start_in_insert_mode = true,
			show_token_count = true,
		},
		action_palette = { provider = "snacks" },
		diff = { enabled = true },
	},

	-- Chats are saved and browsable. Without this a chat buffer dies with the
	-- Neovim session, which on this connection means a conversation that cost
	-- real time to get an answer out of is gone when the tunnel drops and you
	-- restart. `gh` inside the chat browses them, :CodeCompanionHistory from
	-- anywhere.
	extensions = {
		history = {
			enabled = true,
			opts = {
				auto_save = true,
				-- Titles are generated by asking the model — one extra request
				-- per new chat. Worth it: the picker is unusable when every
				-- entry reads "[CodeCompanion]".
				auto_generate_title = true,
				continue_last_chat = false,
				delete_on_clearing_chat = false,
				picker = "snacks",
				expiration_days = 90,
			},
		},
	},

	opts = {
		log_level = "ERROR",
		language = "English",
	},
})

-- ============================================================================
-- Keymaps — <leader>a
-- ============================================================================
local map = vim.keymap.set

local function guarded(cmd)
	return function()
		if require_gateway() then
			vim.cmd(cmd)
		end
	end
end

-- The chat buffer. Toggle, so the same key puts it away.
map({ "n", "v" }, "<leader>aa", guarded("CodeCompanionChat Toggle"), { desc = "AI chat (toggle)" })

-- Everything the prompt library can do, in one picker. Worth pressing before
-- writing a custom prompt — most of what you would write is already in there.
map({ "n", "v" }, "<leader>ap", guarded("CodeCompanionActions"), { desc = "AI actions (palette)" })

-- Push the selection into the chat that is already open.
map("v", "<leader>as", "<cmd>CodeCompanionChat Add<CR>", { desc = "Send selection to chat" })

-- Saved chats. Every chat is written to disk as you go, so this is where a
-- conversation from before the last tunnel drop comes back.
map("n", "<leader>ah", "<cmd>CodeCompanionHistory<CR>", { desc = "AI chat history" })

-- Write a command for the command line rather than for the buffer. The answer
-- lands on `:` for you to read before pressing enter, which is the only sane
-- shape for a generated command.
map("n", "<leader>ax", function()
	if require_gateway() then
		vim.cmd("CodeCompanionCmd")
	end
end, { desc = "AI write a : command" })

-- Inline edit: the "refactor this" key. The answer is written into the buffer
-- as a diff — `g2` accepts a change, `g3` rejects it, `g1` accepts the lot.
local function inline_edit(range)
	return function()
		if not require_gateway() then
			return
		end
		-- vim.ui.input is asynchronous, and by the time its callback runs the
		-- visual selection is gone. Leaving visual mode here, before asking,
		-- is what sets the '< and '> marks the range prefix reads.
		if range then
			vim.cmd("normal! \27")
		end
		vim.ui.input({ prompt = "Inline edit: " }, function(input)
			if input and input ~= "" then
				vim.cmd(("%sCodeCompanion %s"):format(range and "'<,'>" or "", input))
			end
		end)
	end
end

map("n", "<leader>ai", inline_edit(false), { desc = "AI inline edit" })
map("v", "<leader>ai", inline_edit(true), { desc = "AI inline edit (selection)" })

-- Prompt-library entries worth a key of their own. These are the plugin's own
-- prompts, not ones written here: each already carries a tuned system prompt
-- and knows whether it wants the buffer, the selection or the diff.
--
-- The four visual ones go through a range. Leaving visual mode first is what
-- sets '< and '>, and the range is what tells the command it has a selection
-- rather than a whole buffer — without it /explain explains the wrong thing.
local function prompt(alias, range)
	return function()
		if not require_gateway() then
			return
		end
		if range then
			vim.cmd("normal! \27")
		end
		vim.cmd(("%sCodeCompanion /%s"):format(range and "'<,'>" or "", alias))
	end
end

map("v", "<leader>ae", prompt("explain", true), { desc = "AI explain selection" })
map("v", "<leader>af", prompt("fix", true), { desc = "AI fix selection" })
map("v", "<leader>at", prompt("tests", true), { desc = "AI write unit tests" })
map("v", "<leader>ad", prompt("lsp", true), { desc = "AI explain diagnostics" })
map("n", "<leader>aC", prompt("commit", false), { desc = "AI commit message" })

-- Agent mode. Its own key and its own confirmation, because it is
-- categorically different: the agent group can run_command, create_file and
-- delete_file here, in the real working directory, outside any sandbox.
-- CodeCompanion asks before each of those — this is the reminder that those
-- prompts are not a formality.
map("n", "<leader>ag", function()
	if not require_gateway() then
		return
	end
	local answer = vim.fn.confirm(
		"Agent mode can run commands and modify files here.\nThis is NOT the nix-agent sandbox.",
		"&Continue\n&Cancel",
		2
	)
	if answer == 1 then
		vim.cmd("CodeCompanionChat Toggle")
		vim.defer_fn(function()
			vim.api.nvim_put({ "@{agent} " }, "c", true, true)
			vim.cmd("startinsert!")
		end, 120)
	end
end, { desc = "AI agent mode (can edit files!)" })

-- ── Model, from outside the chat buffer ─────────────────────────────────────
-- `ga` already does this, but only once a chat is open and only for that one
-- chat. This sets the default every later chat starts from, which is the thing
-- you want when a provider has just started rate-limiting: change it once,
-- before opening anything.
--
-- The list comes from /v1/models, never from a table here. A list of model
-- names written into this file is a second copy of the dashboard, and it goes
-- stale the first time a provider is added there.
map("n", "<leader>am", function()
	if not require_gateway() then
		return
	end
	local raw = vim.fn.system(("curl -sf --max-time 3 %s/v1/models"):format(GATEWAY))
	local ok, decoded = pcall(vim.json.decode, raw)
	if vim.v.shell_error ~= 0 or not ok or type(decoded) ~= "table" or not decoded.data then
		vim.notify("Gateway served no model list — see :AIDoctor", vim.log.levels.WARN, { title = "AI" })
		return
	end

	-- "(gateway decides)" first and always present: it is the sane default and
	-- the way back after picking a model that turns out to be unavailable.
	local names = { "(gateway decides)" }
	for _, m in ipairs(decoded.data) do
		if m.id then
			table.insert(names, m.id)
		end
	end

	vim.ui.select(names, { prompt = "Default model for new chats:" }, function(choice)
		if not choice then
			return
		end
		MODEL = choice == names[1] and "" or choice
		vim.notify(("Model: %s"):format(choice), vim.log.levels.INFO, { title = "AI" })
	end)
end, { desc = "AI model (default for new chats)" })

-- Status, at a glance: is it up, what will the next chat use.
map("n", "<leader>a?", function()
	local up = gateway_up()
	vim.notify(
		("gateway  %s  %s\nmodel    %s"):format(
			up and "✔ up  " or "✖ down",
			GATEWAY,
			MODEL == "" and "(gateway decides)" or MODEL
		) .. (up and "" or "\n\n  cd ~/dev/aihub && hub start 9router"),
		up and vim.log.levels.INFO or vim.log.levels.WARN,
		{ title = "AI status" }
	)
end, { desc = "AI status" })

-- ── :AIDoctor ───────────────────────────────────────────────────────────────
-- The first thing to run when nothing answers. It separates the failures that
-- look identical from inside the chat buffer: gateway down, gateway up but
-- serving no model, gateway fine and the model rejecting the request.
vim.api.nvim_create_user_command("AIDoctor", function()
	local lines = { "CodeCompanion", ("  endpoint   %s"):format(GATEWAY) }

	if not gateway_up() then
		vim.list_extend(lines, {
			"  gateway    ✖ nothing listening",
			"",
			"  cd ~/dev/aihub && hub start 9router",
		})
		vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "AI doctor" })
		return
	end
	table.insert(lines, "  gateway    ✔ up")

	local raw = vim.fn.system(("curl -sf --max-time 3 %s/v1/models"):format(GATEWAY))
	local ok, decoded = pcall(vim.json.decode, raw)
	if vim.v.shell_error ~= 0 or not ok or type(decoded) ~= "table" or not decoded.data then
		table.insert(lines, "  models     ✖ /v1/models did not answer with a list")
		table.insert(lines, "             the port is open but 9router is not serving the API")
		vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "AI doctor" })
		return
	end

	local names = {}
	for _, m in ipairs(decoded.data) do
		if m.id then
			table.insert(names, m.id)
		end
	end
	if #names == 0 then
		table.insert(lines, "  models     ✖ the list came back empty")
		table.insert(lines, "             no provider is configured in the 9router dashboard")
		vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "AI doctor" })
		return
	end

	table.insert(lines, ("  models     ✔ %d served"):format(#names))
	table.insert(lines, ("  requested  %s"):format(MODEL == "" and "(gateway decides)" or MODEL))
	table.insert(lines, "")
	table.insert(lines, "  " .. table.concat(vim.list_slice(names, 1, math.min(#names, 12)), "  "))
	table.insert(lines, "")
	table.insert(lines, "  ga in the chat buffer switches adapter and model")

	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "AI doctor" })
end, { desc = "Check the AI gateway and the models it serves" })
