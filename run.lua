local backend = require "tacky.backend.init"
local compile = require "tacky.compile"
local logger = require "tacky.logger"
local optimise = require "tacky.analysis.optimise"
local parser = require "tacky.parser"
local pprint = require "tacky.pprint"
local resolve = require "tacky.analysis.resolve"

local paths = { "?", "lib/?" }
local inputs, output, verbosity, run, prelude, time = {}, "out", 0, false, "lib/prelude", false

-- Tiny Lua stub
if _VERSION:find("5.1") then
	function load(str, name, _, env)
		local f, e = loadstring(str, name)
		if not f then return false, e end
		if env then setfenv(f, env) end
		return f
	end
end

local args = table.pack(...)
local i = 1
while i <= args.n do
	local arg = args[i]
	if arg == "--output" or arg == "-o" then
		i = i + 1
		output = args[i] or error("Expected output after " .. arg, 0)
	elseif arg == "-v" then
		verbosity = verbosity + 1
		logger.setVerbosity(verbosity)
	elseif arg == "--explain" or arg == "-e" then
		logger.setExplain(true)
	elseif arg == "--run" or arg == "-r" then
		run = true
	elseif arg == "--time" or arg == "-t" then
		time = true
	elseif arg == "--include" or arg == "-i" then
		i = i + 1
		local path = args[i] or error("Expected directory after " .. arg, 0)
		path = path:gsub("\\", "/"):gsub("^%./", "")
		if not path:find("?") then
			if path:sub(#path, #path) == "/" then
				path = path .. "?"
			else
				path = path .. "/?"
			end
		end
		paths[#paths + 1] = path
	elseif arg == "--prelude" or arg == "-p" then
		i = i + 1
		prelude = args[i] or error("Expected prelude after " .. arg, 0)
	elseif arg:sub(1, 1) == "-" then
		error("Unknown option " .. arg, 0)
	else
		inputs[#inputs + 1] = arg:gsub("\\", "/"):gsub("^%./", "")
	end

	i = i + 1
end

logger.printVerbose("Using path: " .. table.concat(paths, ":"))

local libEnv = {}
local libMeta = {}
local libs = {}
local libCache = {}
local global = setmetatable({ _libs = libEnv }, {__index = _ENV or _G})
local compileState = backend.lua.backend.createState(libMeta)

local rootScope = resolve.createScope()
rootScope.isRoot = true
local variables, states = {}, {}
local out = {}

for _, var in pairs(resolve.rootScope.variables) do variables[tostring(var)] = var end

local function printRepl(x)
	local function map(f, xs)
		for i = 1, #xs do
			xs[i] = f(xs[i])
		end
		return xs
	end
	if type(x) == 'table' then
		if x.n then
			return ("(%s)"):format(table.concat(map(printRepl, x), " "))
		elseif x.tag and x.tag == 'symbol' then
			return x.contents
		end
	elseif type(x) == 'string' then
		return ("%q"):format(x)
	else
		return tostring(x)
	end
end

local function libLoader(name, scope, resolve)
	if name:sub(-5) == ".lisp" then
		name = name:sub(1, -6)
	end

	local current = libCache[name]
	if current == true then
		error("Loop: already loading " .. name, 2)
	elseif current ~= nil then
		return true, current
	end

	logger.printVerbose("Loading " .. name)

	libCache[name] = true

	local lib = { name = name }

	local path, handle
	local looked = {}
	if resolve == false then
		path = name
		looked[#looked + 1] = path

		handle = io.open(path .. ".lisp", "r")
	else
		for i = 1, #paths do
			path = paths[i]:gsub("%?", name)
			looked[#looked + 1] = path

			handle = io.open(path .. ".lisp", "r")
			if handle then
				break
			end
		end
	end

	if not handle then return false, "Cannot find " .. name .. " (looked at " .. table.concat(looked, ", ") .. ")" end

	lib.lisp = handle:read("*a")
	lib.path = path
	handle:close()

	for i = 1, #libs do
		local tempLib = libs[i]
		if tempLib.path == path then
			logger.printVerbose("Reusing " .. tempLib.name .. " for " .. name)
			local current = libCache[tempLib.name]
			libCache[name] = current
			return true, current
		end
	end

	local handle = io.open(path .. ".lua", "r")
	if handle then
		lib.native = handle:read("*a")
		handle:close()

		local fun, msg = load(lib.native, "@" .. lib.name, "t", _ENV)
		if not fun then error(msg, 0) end

		for k, v in pairs(fun()) do
			-- TODO: Make name specific for each library
			libEnv[k] = v
		end

		-- Parse the meta info
		local metaHadle = io.open(path .. ".meta.lua", "r")
		if metaHadle then
			local meta = metaHadle:read("*a")
			metaHadle:close()

			local fun, msg = load(meta, "@" .. lib.name .. ".meta", "t", _ENV)
			if not fun then error(msg, 0) end

			for k, v in pairs(fun()) do
				if type(v.contents) == "string" then
					local buffer = {tag="list"}
					local str = v.contents
					local current = 1
					while current <= #str do
						local start, finish = str:find("%${(%d+)}", current)
						if not start then
							buffer[#buffer + 1] = str:sub(current, #str)
							current = #str + 1
						else
							if start > current then
								buffer[#buffer + 1] = str:sub(current, start - 1)
							end
							buffer[#buffer + 1] = tonumber(str:sub(start + 2, finish - 1))
							current = finish + 1
						end
					end

					buffer.n = #buffer
					v.contents = buffer
				end

				libMeta[k] = v
			end
		end
	end

	local start = os.clock()
	local lexed = parser.lex(lib.lisp, lib.path)
	local parsed = parser.parse(lexed, lib.lisp)
	if time then print(lib.path .. " parsed in " .. (os.clock() - start)) end

	if not scope then
		scope = rootScope:child()
		scope.isRoot = true
	end
	local compiled, state = compile.compile(parsed, global, variables, states, scope, compileState, libLoader)

	libs[#libs + 1] = lib
	libCache[name] = state
	for i = 1, #compiled do
		out[#out + 1] = compiled[i]
	end

	logger.printVerbose("Loaded " .. name)

	return true, state
end

assert(libLoader(prelude, rootScope, false))

if #inputs == 0 then
	local scope = rootScope

	local function tryParse(str)
		local start = os.clock()
		local ok, lexed = pcall(parser.lex, str, "<stdin>")
		if not ok then
			logger.printError(lexed)
			return {}
		end

		local ok, parsed = pcall(parser.parse, lexed)
		if not ok then
			logger.printError(parsed)
			return {}
		end

		if time then print("<stdin>" .. " parsed in " .. (os.clock() - start)) end

		local ok, msg, state = pcall(compile.compile, parsed, global, variables, states, scope, compileState, libLoader)
		if not ok then
			logger.printError(msg)
			return {}
		end

		return state
	end

	local buffer = {}
	while true do
		if #buffer == 0 then
			io.write("\27[92m>\27[0m ")
		else
			io.write("\27[92m.\27[0m ")
		end
		io.flush()

		local line = io.read("*l")

		if not line and #buffer == 0 then
			-- Exit if we have nothing to run
			break
		elseif line and line:sub(#line, #line) == "\\" then
			buffer[#buffer + 1] = line:sub(1, #line - 1) .. "\n"
		elseif line and #buffer > 0 and #line > 0 then
			buffer[#buffer + 1] = line
		else
			local data = table.concat(buffer) .. (line or "")
			scope = scope:child()
			scope.isRoot = true

			buffer = {}

			local state = tryParse(data)
			if #state ~= 0 then
				local current = 0
				local exec = coroutine.create(function()
					for i = 1, #state do
						current = state[i]
						current:get()
					end
				end)

				while true do
					local ok, data = coroutine.resume(exec)
					if not ok then
						logger.printError(data)
						break
					end

					if coroutine.status(exec) == "dead" then
						print("\27[96m" .. printRepl(state[#state]:get()) .. "\27[0m")
						break
					else
						local states = data.states
						if states[1] == current and not current.var then
							table.remove(states, 1)
							local ok, msg = pcall(compile.executeStates, compileState, states, global)
							if not ok then logger.printError(msg) break end

							local str = backend.lua.prelude() .. "\n" .. backend.lua.expression(current.node, compileState, "return ")
							local fun, msg = load(str, "=<input>", "t", global)
							if not fun then error(msg .. ":\n" .. str, 0) end

							local ok, res = xpcall(fun, debug.traceback)
							if not ok then logger.printError(res) break end

							current:executed(res)
						else
							local ok, msg = pcall(compile.executeStates, compileState, states, global)
							if not ok then logger.printError(msg) break end
						end
					end
				end
			end
		end
	end

	return
end

for i = 1, #inputs do
	assert(libLoader(inputs[i], nil, false))
end

out.n = #out
out.tag = "list"

local start = os.clock()
out = optimise(out)
if time then print("Optimised in " .. (os.clock() - start)) end

local state = backend.lua.backend.createState(libMeta)
local compiledLua = backend.lua.block(out, state, 1, "return ")
local handle = io.open(output .. ".lua", "w")

handle:write(backend.lua.prelude())

handle:write("local _libs = {}\n")
for i = 1, #libs do
	local native = libs[i].native
	if native then
		handle:write("local _temp = (function()\n")

		-- Indent the libraries to make them look prettier
		for line in native:gmatch("[^\n]*") do
			if line == "" then
			else
				handle:write("\t")
				handle:write(line)
				handle:write("\n")
			end
		end
		handle:write("end)()\nfor k, v in pairs(_temp) do _libs[k] = v end\n")
	end
end

-- Predeclare all variables
-- TEMP HACK to prevent "too many local variable" errors.
--[[
handle:write("local ")
local first = true
for var, _ in pairs(env) do
	if first then
		first = false
	else
		handle:write(", ")
	end

	handle:write(backend.lua.backend.escapeVar(var))
end
]]
handle:write("\n")
handle:write(compiledLua)
handle:close()

local compiledLisp = backend.lisp.block(out, 1)
local handle = io.open(output .. ".lisp", "w")

handle:write(compiledLisp)
handle:close()

if run then
	dofile(output .. ".lua")
end
