-- Error in library: dev.rayfox.testlib >
-- FoxBox version: 3.2
-- fox.lua version: 1.2
-- Unix time: 1778008615
-- DocType version: Bea G2
--> ============  METADATA  ============ <--


local Box = {}
Box._config = {
	package = "dev.rayfox.testlib", -- Your package name
	version = 1.0, -- dev.rayfox.testlib version
	deps = {},
	optional = {
		["fxas.random"] = {">=", "1.0"}
	}
	-- Modes: >=, <=, >, <, ==, ~=
	-- You can mix different modes:
	-- {{">=", 1.0}, {"<", 2.3}, {"~=", 1.58}, ...}
	-- Or 'deps = nil' if none
}

--> ============   CONFIG   ============ <--


local syslib = ...
if type(syslib) ~= "table" then
	return Box
else
	syslib = load(Fox.syslib)(Box._config)
end

--> ============   SYSLIB   ============ <--
--------------------------------------------
--> ============ YOUR CODE: ============ <--

function Box.test()
	Fox.log("test!")
end

syslib.log("Init!")

if syslib.included "fxas.random" then
	syslib.import "fxas.random"
	function Box.rand(x)
		return fxas.random.string(x, true)
	end
end

return Box
