local state = {
	_availableCustomDimensions01 = {},
	_availableCustomDimensions02 = {},
	_availableCustomDimensions03 = {},
	_availableResourceCurrencies = {},
	_availableResourceItemTypes = {},
	_build = "",
	_gameKey = "",
	_secretKey = "",
	Initialized = false
}

local validation = require(script.Parent.Validation)
local utilities = require(script.Parent.Utilities)
local logger = require(script.Parent.Logger)
local http_api = require(script.Parent.HttpApi)
local store = require(script.Parent.Store)
local settings = require(script.Parent.Settings)
local events = require(script.Parent.Events)
local HTTP = game:GetService("HttpService")
local GameAnalyticsCommandCenter

local function getClientTsAdjusted(playerId)
	local PlayerData = store.PlayerCache[playerId]
	if not PlayerData then
		return os.time()
	end
	local clientTs = os.time()
	local clientTsAdjustedInteger = clientTs + PlayerData.ClientServerTimeOffset
	if validation:validateClientTs(clientTsAdjustedInteger) then
		return clientTsAdjustedInteger;
	else
		return clientTs
	end
end

local function populateConfigurations(playerId)
	local PlayerData = store.PlayerCache[playerId]
	local sdkConfig = PlayerData.SdkConfig
	
	if sdkConfig["configurations"] then
		local configurations = sdkConfig["configurations"]
		
		for _,configuration in pairs(configurations) do
			if configuration then
				local key = configuration["key"] or ""
				local start_ts = configuration["start"] or 0
				local end_ts = configuration["end"] or math.huge
				local client_ts_adjusted = getClientTsAdjusted(playerId)

				if string.len(key) > 0 and configuration["value"] and client_ts_adjusted > start_ts and client_ts_adjusted < end_ts then
					PlayerData.Configurations[key] = configuration["value"]
					logger:d("configuration added: key=" .. configuration["key"] .. ", value=" .. configuration["value"])
				end
			end
		end
	end

	PlayerData.CommandCenterIsReady = true
	GameAnalyticsCommandCenter = GameAnalyticsCommandCenter or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsCommandCenter")
	GameAnalyticsCommandCenter:FireAllClients()
end

function state:sessionIsStarted(playerId)
	local PlayerData = store.PlayerCache[playerId]
	if not PlayerData then
		return false
	end
	return PlayerData.SessionStart ~= 0
end

function state:isEnabled(playerId)
	local PlayerData = store.PlayerCache[playerId]
	if not PlayerData then
		return false
	elseif PlayerData.SdkConfig and PlayerData.SdkConfig["enabled"] == false then
		return false
	elseif not PlayerData.InitAuthorized then
		return false
	else
		return true
	end
end

function state:validateAndFixCurrentDimensions(playerId)
	local PlayerData = store.PlayerCache[playerId]
	
	-- validate that there are no current dimension01 not in list
	if not validation:validateDimension(self._availableCustomDimensions01, PlayerData.CurrentCustomDimension01) then
		logger:d("Invalid dimension01 found in variable. Setting to nil. Invalid dimension: " .. PlayerData.CurrentCustomDimension01)
	end
	-- validate that there are no current dimension02 not in list
	if not validation:validateDimension(self._availableCustomDimensions02, PlayerData.CurrentCustomDimension02) then
		logger:d("Invalid dimension02 found in variable. Setting to nil. Invalid dimension: " .. PlayerData.CurrentCustomDimension02)
	end
	-- validate that there are no current dimension03 not in list
	if not validation:validateDimension(self._availableCustomDimensions03, PlayerData.CurrentCustomDimension03) then
		logger:d("Invalid dimension03 found in variable. Setting to nil. Invalid dimension: " .. PlayerData.CurrentCustomDimension03)
	end
end

function state:setAvailableCustomDimensions01(availableCustomDimensions)
	if not validation:validateCustomDimensions(availableCustomDimensions) then 
		return
	end
	
	self._availableCustomDimensions01 = availableCustomDimensions
	
	logger:i("Set available custom01 dimension values: (" .. table.concat(availableCustomDimensions, ", ") .. ")")
end

function state:setAvailableCustomDimensions02(availableCustomDimensions)
	if not validation:validateCustomDimensions(availableCustomDimensions) then 
		return
	end
	
	self._availableCustomDimensions02 = availableCustomDimensions
	
	logger:i("Set available custom02 dimension values: (" .. table.concat(availableCustomDimensions, ", ") .. ")")
end

function state:setAvailableCustomDimensions03(availableCustomDimensions)
	if not validation:validateCustomDimensions(availableCustomDimensions) then 
		return
	end
	
	self._availableCustomDimensions03 = availableCustomDimensions
	
	logger:i("Set available custom03 dimension values: (" .. table.concat(availableCustomDimensions, ", ") .. ")")
end

function state:setAvailableResourceCurrencies(availableResourceCurrencies)
	if not validation:validateResourceCurrencies(availableResourceCurrencies) then 
		return
	end
	
	self._availableResourceCurrencies = availableResourceCurrencies
	
	logger:i("Set available resource currencies: (" .. table.concat(availableResourceCurrencies, ", ") .. ")")
end

function state:setAvailableResourceItemTypes(availableResourceItemTypes)
	if not validation:validateResourceCurrencies(availableResourceItemTypes) then 
		return
	end
	
	self._availableResourceItemTypes = availableResourceItemTypes
	
	logger:i("Set available resource item types: (" .. table.concat(availableResourceItemTypes, ", ") .. ")")
end

function state:setBuild(build)
	if not validation:validateBuild(build) then
		logger:w("Validation fail - configure build: Cannot be null, empty or above 32 length. String: " .. build)
		return
	end
	
	self._build = build
	logger:i("Set build version: " .. build)
end

function state:setCustomDimension01(playerId, dimension)
	local PlayerData = store.PlayerCache[playerId]
	PlayerData.CurrentCustomDimension01 = dimension
end

function state:setCustomDimension02(playerId, dimension)
	local PlayerData = store.PlayerCache[playerId]
	PlayerData.CurrentCustomDimension02 = dimension
end

function state:setCustomDimension03(playerId, dimension)
	local PlayerData = store.PlayerCache[playerId]
	PlayerData.CurrentCustomDimension03 = dimension
end

function state:startNewSession(playerId)
	logger:i("Starting a new session.")
	local PlayerData = store.PlayerCache[playerId]
	
	-- make sure the current custom dimensions are valid
	state:validateAndFixCurrentDimensions(playerId)
	
	local initResult = http_api:initRequest(settings.GameKey, settings.SecretKey, PlayerData, playerId)
	local statusCode = initResult.statusCode
	local responseBody = initResult.body
	
	if statusCode == http_api.EGAHTTPApiResponse.Ok and responseBody then
		-- set the time offset - how many seconds the local time is different from servertime
		local timeOffsetSeconds = 0
		local serverTs = responseBody["server_ts"] or -1
		if serverTs > 0 then
			local clientTs = os.time()
			timeOffsetSeconds = serverTs - clientTs
		end
		
		responseBody["time_offset"] = timeOffsetSeconds
		
		PlayerData.SdkConfig = responseBody
		PlayerData.InitAuthorized = true
	elseif statusCode == http_api.EGAHTTPApiResponse.Unauthorized then
		logger:w("Initialize SDK failed - Unauthorized")
		PlayerData.InitAuthorized = false
	else
		-- log the status if no connection
		if statusCode == http_api.EGAHTTPApiResponse.NoResponse or statusCode == http_api.EGAHTTPApiResponse.RequestTimeout then
			logger:i("Init call (session start) failed - no response. Could be offline or timeout.")
		elseif statusCode == http_api.EGAHTTPApiResponse.BadResponse or statusCode == http_api.EGAHTTPApiResponse.JsonEncodeFailed or statusCode == http_api.EGAHTTPApiResponse.JsonDecodeFailed then
			logger:i("Init call (session start) failed - bad response. Could be bad response from proxy or GA servers.")
		elseif statusCode == http_api.EGAHTTPApiResponse.BadRequest or statusCode == http_api.EGAHTTPApiResponse.UnknownResponseCode then
			logger:i("Init call (session start) failed - bad request or unknown response.")
		end
		
		PlayerData.InitAuthorized = true
	end
	
	-- set offset in state (memory) from current config (config could be from cache etc.)
	PlayerData.ClientServerTimeOffset = PlayerData.SdkConfig["time_offset"] or 0
	
	-- populate configurations
	populateConfigurations(playerId)
	
	if not state:isEnabled(playerId) then
		logger:w("Could not start session: SDK is disabled.")
		return
	end
	
	PlayerData.SessionID = HTTP:GenerateGUID(false):lower()
	PlayerData.SessionStart = getClientTsAdjusted(playerId)
	
	events:addSessionStartEvent(playerId)
end

function state:endSession(playerId)
	if state.Initialized then
		logger:i("Ending session.")
		if state:isEnabled(playerId) and state:sessionIsStarted(playerId) then
			events:addSessionEndEvent(playerId)
		end
	end
end

function state:getConfigurationStringValue(playerId, key, defaultValue)
	local PlayerData = store.PlayerCache[playerId]
	return PlayerData.Configurations[key] or defaultValue
end

function state:isCommandCenterReady(playerId)
	local PlayerData = store.PlayerCache[playerId]
	return PlayerData.CommandCenterIsReady
end

function state:getConfigurationsContentAsString(playerId)
	local PlayerData = store.PlayerCache[playerId]
	return HTTP:JSONEncode(PlayerData.Configurations)
end

return state
