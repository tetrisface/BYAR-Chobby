-- Unit tests for libs/json.lua pretty-printing (encode(o, true)).
-- Run from the repository root: mise exec -- luajit tests/test_json_pretty.lua
loadstring = loadstring or load -- the engine runs LuaJIT (Lua 5.1); keep 5.2+ interpreters working

local Json = dofile("libs/json.lua")

local function deepEqual(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do
		if not deepEqual(v, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

local sample = {
	["My Preset"] = {
		["Map"] = "Full Metal Plate 1.7",
		["Modoptions"] = { startmetal = "1000", ranked_game = "0" },
		["Start Boxes"] = {
			{ left = 0, right = 0.25, top = 0, bottom = 1 },
			{ left = 0.75, right = 1, top = 0, bottom = 1 },
		},
	},
	["empty"] = {},
}

-- pretty output is tab indented and round-trips through the module's own decoder
local pretty = Json.encode(sample, true)
assert(pretty:find("\n\t", 1, true), "pretty output must be tab indented")
assert(not pretty:find("\n ", 1, true), "pretty output must not use space indentation")
assert(deepEqual(sample, Json.decode(pretty)), "pretty output did not round-trip")

-- empty tables stay inline
assert(pretty:find('"empty": {}', 1, true) or pretty:find('"empty": []', 1, true),
	"empty table must stay inline")

-- compact mode is unchanged: single line, no key spacing (guards the other encode call sites)
local compact = Json.encode(sample)
assert(not compact:find("\n", 1, true), "compact output must stay single-line")
assert(not compact:find('": ', 1, true), "compact output must not gain key spacing")
assert(deepEqual(sample, Json.decode(compact)), "compact output did not round-trip")

print("test_json_pretty: all assertions passed")
