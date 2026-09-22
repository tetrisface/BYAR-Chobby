-- Unit tests for libs/json.lua CR escaping and repair().
-- Run from the repository root: mise exec -- luajit tests/test_json_escape.lua
loadstring = loadstring or load -- the engine runs LuaJIT (Lua 5.1); keep 5.2+ interpreters working

local Json = dofile("libs/json.lua")

-- control/escape bytes built via string.char: autotest.sh rejects raw CR in tracked files
local CR = string.char(13)
local LF = string.char(10)
local BS = string.char(92)

-- encode escapes CR: a value ending in CRLF must not leak raw bytes into the JSON
local encoded = Json.encode({ tweak = "QmFzZTY0" .. CR .. LF })
assert(not encoded:find(CR, 1, true), "raw CR leaked into encoded JSON")
assert(not encoded:find(LF, 1, true), "raw LF leaked into encoded JSON")
assert(Json.decode(encoded).tweak == "QmFzZTY0" .. CR .. LF, "CRLF value did not round-trip")

-- repair: compact JSON with a raw CR inside a string value (the optionsPresets.json bug shape)
local corruptCompact = '{"p":{"tweak":"QmFzZTY0' .. CR .. BS .. 'n"}}'
assert(not pcall(Json.decode, corruptCompact), "corrupt input unexpectedly decoded; repair untested")
local repaired = Json.repair(corruptCompact)
assert(Json.decode(repaired).p.tweak == "QmFzZTY0" .. CR .. LF, "repair lost the CR value")

-- repair: formatted JSON with CRLF line endings; only in-string bytes may change
local corruptPretty = '{' .. CR .. LF .. '\t"a": "x' .. CR .. 'y",' .. CR .. LF .. '\t"b": [1, 2]' .. CR .. LF .. '}'
local repairedPretty = Json.repair(corruptPretty)
local decodedPretty = Json.decode(repairedPretty)
assert(decodedPretty.a == "x" .. CR .. "y", "repair lost the in-string CR")
assert(decodedPretty.b[2] == 2, "repair broke surrounding structure")
assert(repairedPretty:find('{' .. CR .. LF, 1, true) == 1, "repair must not touch structural whitespace")

-- repair is the identity on already-valid content (escapes must not be double-escaped)
local valid = '{"a":"x' .. BS .. 'ny","b":[1,2]}'
assert(Json.repair(valid) == valid, "repair changed already-valid JSON")

print("test_json_escape: all assertions passed")
