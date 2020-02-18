local function readonlytable(table)
	return setmetatable({}, {
		__index = table,
		__metatable = false,
		__newindex = function(t, k, v)
			error("Attempt to modify read-only table: " .. t .. ", key=" .. k .. ", value=" .. v)
		end,
	})
end

return readonlytable({
	debug = "debug",
	info = "info",
	warning = "warning",
	error = "error",
	critical = "critical",
})
