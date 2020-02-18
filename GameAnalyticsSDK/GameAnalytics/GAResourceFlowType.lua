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
	Source = "Source",
	Sink = "Sink",
})
