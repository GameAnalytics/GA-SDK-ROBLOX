local validation = require(script.Parent.Validation)
local logger = require(script.Parent.Logger)
local http_api = require(script.Parent.HttpApi)
local store = require(script.Parent.Store)
local events = require(script.Parent.Events)
local HTTP = game:GetService("HttpService")

local state = {
	_availableCustomDimensions01 = {},
	_availableCustomDimensions02 = {},
	_availableCustomDimensions03 = {},
	_availableGamepasses = {},
	_enableEventSubmission = true,
	Initialized = false,
	ReportErrors = true,
	UseCustomUserId = false,
	AutomaticSendBusinessEvents = true,
	ConfigsHash = "",
}

local GameAnalyticsRemoteConfigs

local function getClientTsAdjusted(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	if not PlayerData then
		return os.time()
	end

	local clientTs = os.time()
	local clientTsAdjustedInteger = clientTs + PlayerData.ClientServerTimeOffset
	if validation:validateClientTs(clientTsAdjustedInteger) then
		return clientTsAdjustedInteger
	else
		return clientTs
	end
end

local function populateConfigurations(player)
	local PlayerData = store:GetPlayerDataFromCache(player.UserId)
	local sdkConfig = PlayerData.SdkConfig

	if sdkConfig["configs"] then
		local configurations = sdkConfig["configs"]

		for _, configuration in pairs(configurations) do
			if configuration then
				local key = configuration["key"] or ""
				local start_ts = configuration["start_ts"] or 0
				local end_ts = configuration["end_ts"] or math.huge
				local client_ts_adjusted = getClientTsAdjusted(player.UserId)

				if #key > 0 and configuration["value"] and client_ts_adjusted > start_ts and client_ts_adjusted < end_ts then
					PlayerData.Configurations[key] = configuration["value"]
					logger:d("configuration added: key=" .. configuration["key"] .. ", value=" .. configuration["value"])
				end
			end
		end
	end

	logger:i("Remote configs populated")

	PlayerData.RemoteConfigsIsReady = true
	GameAnalyticsRemoteConfigs = GameAnalyticsRemoteConfigs or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsRemoteConfigs")
	GameAnalyticsRemoteConfigs:FireClient(player, PlayerData.Configurations)
end

function state:sessionIsStarted(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	if not PlayerData then
		return false
	end

	return PlayerData.SessionStart ~= 0
end

function state:isEnabled(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	if not PlayerData then
		return false
	elseif not PlayerData.InitAuthorized then
		return false
	else
		return true
	end
end

function state:validateAndFixCurrentDimensions(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)

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

function state:setAvailableGamepasses(availableGamepasses)
	self._availableGamepasses = availableGamepasses
	logger:i("Set available game passes: (" .. table.concat(availableGamepasses, ", ") .. ")")
end

function state:setEventSubmission(flag)
	self._enableEventSubmission = flag
end

function state:isEventSubmissionEnabled()
	return self._enableEventSubmission
end

function state:setCustomDimension01(playerId, dimension)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	PlayerData.CurrentCustomDimension01 = dimension
end

function state:setCustomDimension02(playerId, dimension)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	PlayerData.CurrentCustomDimension02 = dimension
end

function state:setCustomDimension03(playerId, dimension)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	PlayerData.CurrentCustomDimension03 = dimension
end

function state:startNewSession(player, teleportData)
	if state:isEventSubmissionEnabled() and teleportData == nil then
		logger:i("Starting a new session.")
	end

	local PlayerData = store:GetPlayerDataFromCache(player.UserId)

	-- make sure the current custom dimensions are valid
	state:validateAndFixCurrentDimensions(player.UserId)

	local initResult = http_api:initRequest(events.GameKey, events.SecretKey, events.Build, PlayerData, player.UserId)
	local statusCode = initResult.statusCode
	local responseBody = initResult.body

	if (statusCode == http_api.EGAHTTPApiResponse.Ok or statusCode == http_api.EGAHTTPApiResponse.Created) and responseBody then
		-- set the time offset - how many seconds the local time is different from servertime
		local timeOffsetSeconds = 0
		local serverTs = responseBody["server_ts"] or -1
		if serverTs > 0 then
			local clientTs = os.time()
			timeOffsetSeconds = serverTs - clientTs
		end

		responseBody["time_offset"] = timeOffsetSeconds

		if not (statusCode == http_api.EGAHTTPApiResponse.Created) then
			local sdkConfig = PlayerData.SdkConfig

			if sdkConfig["configs"] then
				responseBody["configs"] = sdkConfig["configs"]
			end

			if sdkConfig["ab_id"] then
				responseBody["ab_id"] = sdkConfig["ab_id"]
			end

			if sdkConfig["ab_variant_id"] then
				responseBody["ab_variant_id"] = sdkConfig["ab_variant_id"]
			end
		end

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
	PlayerData.ConfigsHash = PlayerData.SdkConfig["configs_hash"] or ""
	PlayerData.AbId = PlayerData.SdkConfig["ab_id"] or ""
	PlayerData.AbVariantId = PlayerData.SdkConfig["ab_variant_id"] or ""

	-- populate configurations
	populateConfigurations(player)

	if not state:isEnabled(player.UserId) then
		logger:w("Could not start session: SDK is disabled.")
		return
	end

	if teleportData then
		PlayerData.SessionID = teleportData.SessionID
		PlayerData.SessionStart = teleportData.SessionStart
	else
		PlayerData.SessionID = string.lower(HTTP:GenerateGUID(false))
		PlayerData.SessionStart = getClientTsAdjusted(player.UserId)
	end

	if state:isEventSubmissionEnabled() then
		events:addSessionStartEvent(player.UserId, teleportData)
	end
end

function state:endSession(playerId)
	if state.Initialized and state:isEventSubmissionEnabled() then
		logger:i("Ending session.")
		if state:isEnabled(playerId) and state:sessionIsStarted(playerId) then
			events:addSessionEndEvent(playerId)
			store.PlayerCache[playerId] = nil
		end
	end
end

function state:getRemoteConfigsStringValue(playerId, key, defaultValue)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	return PlayerData.Configurations[key] or defaultValue
end

function state:isRemoteConfigsReady(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	return PlayerData.RemoteConfigsIsReady
end

function state:getRemoteConfigsContentAsString(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	return HTTP:JSONEncode(PlayerData.Configurations)
end

return state
