local HTTP = game:GetService("HttpService")

local RemoteConfigs = {}

function RemoteConfigs.newRecord()
	return {
		values = {},
		types = {},
		tracking = {},
		hash = "",
		abId = "",
		abVariantId = "",
		ready = false,
	}
end

local function isActive(configuration, nowTs)
	local startTs = configuration.start_ts or -math.huge
	local endTs = configuration.end_ts or math.huge
	return nowTs > startTs and nowTs < endTs
end

local function isComplete(configuration)
	return typeof(configuration.key) == "string"
		and #configuration.key > 0
		and configuration.value ~= nil
		and configuration.vsn ~= nil
end

function RemoteConfigs.build(configs, nowTs)
	local values = {}
	local types = {}
	local tracking = {}
	local trackingIndex = {}

	for _, configuration in ipairs(configs or {}) do
		if typeof(configuration) == "table" and isComplete(configuration) and isActive(configuration, nowTs) then
			local key = configuration.key
			local entry = {
				key = key,
				id = if configuration.id ~= nil then tostring(configuration.id) else "",
				vsn = configuration.vsn,
			}

			values[key] = configuration.value
			types[key] = configuration.type
			if trackingIndex[key] then
				tracking[trackingIndex[key]] = entry
			else
				table.insert(tracking, entry)
				trackingIndex[key] = #tracking
			end
		end
	end

	return values, tracking, types
end

function RemoteConfigs.getValueAsString(values, key, defaultValue)
	local value = values[key]
	if value == nil then
		return defaultValue
	end
	if typeof(value) == "table" then
		return HTTP:JSONEncode(value)
	end
	return tostring(value)
end

function RemoteConfigs.getValueAsJson(values, types, key, defaultValue)
	local value = values[key]
	if types[key] ~= "json" or typeof(value) ~= "string" then
		return defaultValue
	end

	local ok, decoded = pcall(HTTP.JSONDecode, HTTP, value)
	if ok and decoded ~= nil then
		return decoded
	end
	return defaultValue
end

function RemoteConfigs.getContentAsString(values)
	return HTTP:JSONEncode(values)
end

return RemoteConfigs
