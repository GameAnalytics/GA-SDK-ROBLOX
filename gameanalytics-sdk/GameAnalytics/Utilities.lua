local utilities = {}

function utilities:isStringNullOrEmpty(s)
	return (not s) or #s == 0
end

function utilities:stringArrayContainsString(array, search)
	if #array == 0 then
		return false
	end

	for _, s in ipairs(array) do
		if s == search then
			return true
		end
	end

	return false
end

return utilities
