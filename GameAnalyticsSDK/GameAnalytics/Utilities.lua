local utilities = {}

function utilities:isStringNullOrEmpty(s)
	return (not s) or string.len(s) == 0
end

function utilities:stringArrayContainsString(array, search)
	if #array == 0 then
		return false
	end
	
	for _,s in pairs(array) do
		if s == search then
			return true
		end
	end
	
	return false
end

return utilities
