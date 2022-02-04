local GAResourceFlowType = require(script.GAResourceFlowType)
local GAProgressionStatus = require(script.GAProgressionStatus)
local GAErrorSeverity = require(script.GAErrorSeverity)

local ga = {
	EGAResourceFlowType = GAResourceFlowType,
	EGAProgressionStatus = GAProgressionStatus,
	EGAErrorSeverity = GAErrorSeverity,
}

local logger = require(script.Logger)
local threading = require(script.Threading)
local state = require(script.State)
local validation = require(script.Validation)
local store = require(script.Store)
local events = require(script.Events)
local utilities = require(script.Utilities)
local Players = game:GetService("Players")
local MKT = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local ScriptContext = game:GetService("ScriptContext")
local Postie = require(script.Postie)
local OnPlayerReadyEvent
local ProductCache = {}
local ONE_HOUR_IN_SECONDS = 3600
local MaxErrorsPerHour = 10
local ErrorDS = {}
local errorCountCache = {}
local errorCountCacheKeys = {}

local InitializationQueue = {}
local InitializationQueueByUserId = {}

local function addToInitializationQueue(func, ...)
	if InitializationQueue ~= nil then
		table.insert(InitializationQueue, {
			Func = func;
			Args = {...};
		})

		logger:i("Added event to initialization queue")
	else
		--This should never happen
		logger:w("Initialization queue already cleared.")
	end
end

local function addToInitializationQueueByUserId(userId, func, ...)
	if not ga:isPlayerReady(userId) then
		if InitializationQueueByUserId[userId] == nil then
			InitializationQueueByUserId[userId] = {}
		end

		table.insert(InitializationQueueByUserId[userId], {
			Func = func;
			Args = {...};
		})

		logger:i("Added event to player initialization queue")
	else
		--This should never happen
		logger:w("Player initialization queue already cleared.")
	end
end


-- local functions
local function isSdkReady(options)
	local playerId = options["playerId"] or nil
	local needsInitialized = options["needsInitialized"] or true
	local shouldWarn = options["shouldWarn"] or false
	local message = options["message"] or ""

	-- Is SDK initialized
	if needsInitialized and not state.Initialized then
		if shouldWarn then
			logger:w(message .. " SDK is not initialized")
		end

		return false
	end

	-- Is SDK enabled
	if needsInitialized and playerId and not state:isEnabled(playerId) then
		if shouldWarn then
			logger:w(message .. " SDK is disabled")
		end

		return false
	end

	-- Is session started
	if needsInitialized and playerId and not state:sessionIsStarted(playerId) then
		if shouldWarn then
			logger:w(message .. " Session has not started yet")
		end

		return false
	end

	return true
end

function ga:configureAvailableCustomDimensions01(customDimensions)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Available custom dimensions must be set before SDK is initialized")
		return
	end

	state:setAvailableCustomDimensions01(customDimensions)
end

function ga:configureAvailableCustomDimensions02(customDimensions)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Available custom dimensions must be set before SDK is initialized")
		return
	end

	state:setAvailableCustomDimensions02(customDimensions)
end

function ga:configureAvailableCustomDimensions03(customDimensions)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Available custom dimensions must be set before SDK is initialized")
		return
	end

	state:setAvailableCustomDimensions03(customDimensions)
end

function ga:configureAvailableResourceCurrencies(resourceCurrencies)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Available resource currencies must be set before SDK is initialized")
		return
	end

	events:setAvailableResourceCurrencies(resourceCurrencies)
end

function ga:configureAvailableResourceItemTypes(resourceItemTypes)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Available resource item types must be set before SDK is initialized")
		return
	end

	events:setAvailableResourceItemTypes(resourceItemTypes)
end

function ga:configureBuild(build)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Build version must be set before SDK is initialized.")
		return
	end

	events:setBuild(build)
end

function ga:configureAvailableGamepasses(availableGamepasses)
	if isSdkReady({needsInitialized = true, shouldWarn = false}) then
		logger:w("Available gamepasses must be set before SDK is initialized.")
		return
	end

	state:setAvailableGamepasses(availableGamepasses)
end

function ga:startNewSession(player, gaData)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end

		if not state.Initialized then
			logger:w("Cannot start new session. SDK is not initialized yet.")
			return
		end

		state:startNewSession(player, gaData)
	end)
end

function ga:endSession(playerId)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end
		state:endSession(playerId)
	end)
end

function ga:filterForBusinessEvent(text)
	return string.gsub(text, "[^A-Za-z0-9%s%-_%.%(%)!%?]", "")
end

function ga:addBusinessEvent(playerId, options)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end
		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = false, message = "Could not add business event"}) then
			if playerId then
				addToInitializationQueueByUserId(playerId, ga.addBusinessEvent, ga, playerId, options)
			else
				addToInitializationQueue(ga.addBusinessEvent, ga, playerId, options)
			end
			return
		end

		-- Send to events
		local amount = options["amount"] or 0
		local itemType = options["itemType"] or ""
		local itemId = options["itemId"] or ""
		local cartType = options["cartType"] or ""
		local USDSpent = math.floor((amount * 0.7) * 0.35)
		local gamepassId = options["gamepassId"] or nil

		events:addBusinessEvent(playerId, "USD", USDSpent, itemType, itemId, cartType)

		if itemType == "Gamepass" and cartType ~= "Website" then
			local player = Players:GetPlayerByUserId(playerId)
			local playerData = store:GetPlayerData(player)
			if not playerData.OwnedGamepasses then
				playerData.OwnedGamepasses = {}
			end
			table.insert(playerData.OwnedGamepasses, gamepassId)
			store.PlayerCache[playerId] = playerData
			store:SavePlayerData(player)
		end
	end)
end

function ga:addResourceEvent(playerId, options)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end
		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = false, message = "Could not add resource event"}) then
			if playerId then
				addToInitializationQueueByUserId(playerId, ga.addResourceEvent, ga, playerId, options)
			else
				addToInitializationQueue(ga.addResourceEvent, ga, playerId, options)
			end
			return
		end

		-- Send to events
		local flowType = options["flowType"] or 0
		local currency = options["currency"] or ""
		local amount = options["amount"] or 0
		local itemType = options["itemType"] or ""
		local itemId = options["itemId"] or ""

		events:addResourceEvent(playerId, flowType, currency, amount, itemType, itemId)
	end)
end

function ga:addProgressionEvent(playerId, options)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end
		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = false, message = "Could not add progression event"}) then
			if playerId then
				addToInitializationQueueByUserId(playerId, ga.addProgressionEvent, ga, playerId, options)
			else
				addToInitializationQueue(ga.addProgressionEvent, ga, playerId, options)
			end
			return
		end

		-- Send to events
		local progressionStatus = options["progressionStatus"] or 0
		local progression01 = options["progression01"] or ""
		local progression02 = options["progression02"] or nil
		local progression03 = options["progression03"] or nil
		local score = options["score"] or nil

		events:addProgressionEvent(playerId, progressionStatus, progression01, progression02, progression03, score)
	end)
end

function ga:addDesignEvent(playerId, options)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end
		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = false, message = "Could not add design event"}) then
			if playerId then
				addToInitializationQueueByUserId(playerId, ga.addDesignEvent, ga, playerId, options)
			else
				addToInitializationQueue(ga.addDesignEvent, ga, playerId, options)
			end
			return
		end

		-- Send to events
		local eventId = options["eventId"] or ""
		local value = options["value"] or nil

		events:addDesignEvent(playerId, eventId, value)
	end)
end

function ga:addErrorEvent(playerId, options)
	threading:performTaskOnGAThread(function()
		if not state:isEventSubmissionEnabled() then
			return
		end
		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = false, message = "Could not add error event"}) then
			if playerId then
				addToInitializationQueueByUserId(playerId, ga.addErrorEvent, ga, playerId, options)
			else
				addToInitializationQueue(ga.addErrorEvent, ga, playerId, options)
			end
			return
		end

		-- Send to events
		local severity = options["severity"] or 0
		local message = options["message"] or ""

		events:addErrorEvent(playerId, severity, message)
	end)
end

function ga:setEnabledDebugLog(flag)
	if RunService:IsStudio() then
		if flag then
			logger:setDebugLog(flag)
			logger:i("Debug logging enabled")
		else
			logger:i("Debug logging disabled")
			logger:setDebugLog(flag)
		end
	else
		logger:i("setEnabledDebugLog can only be used in studio")
	end
end

function ga:setEnabledInfoLog(flag)
	if flag then
		logger:setInfoLog(flag)
		logger:i("Info logging enabled")
	else
		logger:i("Info logging disabled")
		logger:setInfoLog(flag)
	end
end

function ga:setEnabledVerboseLog(flag)
	if flag then
		logger:setVerboseLog(flag)
		logger:ii("Verbose logging enabled")
	else
		logger:ii("Verbose logging disabled")
		logger:setVerboseLog(flag)
	end
end


function ga:setEnabledEventSubmission(flag)
	threading:performTaskOnGAThread(function()
		if flag then
			state:setEventSubmission(flag)
			logger:i("Event submission enabled")
		else
			logger:i("Event submission disabled")
			state:setEventSubmission(flag)
		end
	end)
end

function ga:setCustomDimension01(playerId, dimension)
	threading:performTaskOnGAThread(function()
		if not validation:validateDimension(state._availableCustomDimensions01, dimension) then
			logger:w("Could not set custom01 dimension value to '" .. dimension .. "'. Value not found in available custom01 dimension values")
			return
		end

		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = true, message = "Could not set custom01 dimension"}) then
			return
		end

		state:setCustomDimension01(playerId, dimension)
	end)
end

function ga:setCustomDimension02(playerId, dimension)
	threading:performTaskOnGAThread(function()
		if not validation:validateDimension(state._availableCustomDimensions02, dimension) then
			logger:w("Could not set custom02 dimension value to '" .. dimension .. "'. Value not found in available custom02 dimension values")
			return
		end

		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = true, message = "Could not set custom02 dimension"}) then
			return
		end

		state:setCustomDimension02(playerId, dimension)
	end)
end

function ga:setCustomDimension03(playerId, dimension)
	threading:performTaskOnGAThread(function()
		if not validation:validateDimension(state._availableCustomDimensions03, dimension) then
			logger:w("Could not set custom03 dimension value to '" .. dimension .. "'. Value not found in available custom03 dimension values")
			return
		end

		if not isSdkReady({playerId = playerId, needsInitialized = true, shouldWarn = true, message = "Could not set custom03 dimension"}) then
			return
		end

		state:setCustomDimension03(playerId, dimension)
	end)
end

function ga:setEnabledReportErrors(flag)
	threading:performTaskOnGAThread(function()
		state.ReportErrors = flag
	end)
end

function ga:setEnabledCustomUserId(flag)
	threading:performTaskOnGAThread(function()
		state.UseCustomUserId = flag
	end)
end

function ga:setEnabledAutomaticSendBusinessEvents(flag)
	threading:performTaskOnGAThread(function()
		state.AutomaticSendBusinessEvents = flag
	end)
end

function ga:addGameAnalyticsTeleportData(playerIds, teleportData)
	local gameAnalyticsTeleportData = {}
	for _, playerId in ipairs(playerIds) do
		local PlayerData = store:GetPlayerDataFromCache(playerId)
		PlayerData.PlayerTeleporting = true
		local data = {
			["SessionID"] = PlayerData.SessionID,
			["Sessions"] = PlayerData.Sessions,
			["SessionStart"] = PlayerData.SessionStart,
		}

		gameAnalyticsTeleportData[tostring(playerId)] = data
	end

	teleportData["gameanalyticsData"] = gameAnalyticsTeleportData

	return teleportData
end

function ga:getRemoteConfigsValueAsString(playerId, options)
	local key = options["key"] or ""
	local defaultValue = options["defaultValue"] or nil
	return state:getRemoteConfigsStringValue(playerId, key, defaultValue)
end

function ga:isRemoteConfigsReady(playerId)
	return state:isRemoteConfigsReady(playerId)
end

function ga:getRemoteConfigsContentAsString(playerId)
	return state:getRemoteConfigsContentAsString(playerId)
end

function ga:PlayerJoined(Player)
	local joinData = Player:GetJoinData()
	local teleportData = joinData.TeleportData
	local gaData = nil

	--Variables
	local PlayerData = store:GetPlayerData(Player)

	if teleportData then
		gaData = teleportData.gameanalyticsData and teleportData.gameanalyticsData[tostring(Player.UserId)]
	end

	local pd = store:GetPlayerDataFromCache(Player.UserId)
	if pd then
		if gaData then
			pd.SessionID = gaData.SessionID
			pd.SessionStart = gaData.SessionStart
		end
		pd.PlayerTeleporting = false
		return
	end

	local PlayerPlatform = "unknown"
	local isSuccessful, platform = Postie.invokeClient("getPlatform", Player, 5)
	if isSuccessful then
		PlayerPlatform = platform
	end

	--Fill Data
	for key, value in pairs(store.BasePlayerData) do
		PlayerData[key] = PlayerData[key] or value
	end

	local countryCodeResult, countryCode = pcall(function()
		return LocalizationService:GetCountryRegionForPlayerAsync(Player)
	end)

	if countryCodeResult then
		PlayerData.CountryCode = countryCode
	end

	store.PlayerCache[Player.UserId] = PlayerData

	PlayerData.Platform = (PlayerPlatform == "Console" and "uwp_console") or (PlayerPlatform == "Mobile" and "uwp_mobile") or (PlayerPlatform == "Desktop" and "uwp_desktop") or "uwp_desktop"
	PlayerData.OS = PlayerData.Platform .. " 0.0.0"

	if not countryCodeResult then
		events:addSdkErrorEvent(Player.UserId, "event_validation", "player_joined", "string_empty_or_null", "country_code", "")
	end

	local PlayerCustomUserId = ""
	if state.UseCustomUserId then
		local isSuccessful, customUserId = Postie.invokeClient("getCustomUserId", Player, 5)
		if isSuccessful then
			PlayerCustomUserId = customUserId
		end
	end

	if not utilities:isStringNullOrEmpty(PlayerCustomUserId) then
		logger:i("Using custom id: " .. PlayerCustomUserId)
		PlayerData.CustomUserId = PlayerCustomUserId
	end

	ga:startNewSession(Player, gaData)

	OnPlayerReadyEvent = OnPlayerReadyEvent or ReplicatedStorage:WaitForChild("OnPlayerReadyEvent")
	OnPlayerReadyEvent:Fire(Player)

	--Validate
	if state.AutomaticSendBusinessEvents then
		--Website gamepasses
		if PlayerData.OwnedGamepasses == nil then --player is new (or is playing after SDK update)
			PlayerData.OwnedGamepasses = {}
			for _, id in ipairs(state._availableGamepasses) do
				if MKT:UserOwnsGamePassAsync(Player.UserId, id) then
					table.insert(PlayerData.OwnedGamepasses, id)
				end
			end
			--Player's data is now up to date. gamepass purchases on website can now be tracked in future visits
			store.PlayerCache[Player.UserId] = PlayerData
			store:SavePlayerData(Player)
		else
			--build a list of the game passes a user owns
			local currentlyOwned = {}
			for _, id in ipairs(state._availableGamepasses) do
				if MKT:UserOwnsGamePassAsync(Player.UserId, id) then
					table.insert(currentlyOwned, id)
				end
			end

			--make a table so it's easier to compare to stored game passes
			local storedGamepassesTable = {}
			for _, id in ipairs(PlayerData.OwnedGamepasses) do
				storedGamepassesTable[id] = true
			end

			--compare stored game passes to currently owned game passses
			for _, id in ipairs(currentlyOwned) do
				if not storedGamepassesTable[id] then
					table.insert(PlayerData.OwnedGamepasses, id)

					local gamepassInfo = ProductCache[id]

					--Cache
					if not gamepassInfo then
						--Get
						gamepassInfo = MKT:GetProductInfo(id, Enum.InfoType.GamePass)
						ProductCache[id] = gamepassInfo
					end

					ga:addBusinessEvent(Player.UserId, {
						amount = gamepassInfo.PriceInRobux,
						itemType = "Gamepass",
						itemId = ga:filterForBusinessEvent(gamepassInfo.Name),
						cartType = "Website",
					})
				end
			end

			store.PlayerCache[Player.UserId] = PlayerData

			store:SavePlayerData(Player)
		end
	end

	local playerEventQueue = InitializationQueueByUserId[Player.UserId]
	if playerEventQueue then
		InitializationQueueByUserId[Player.UserId] = nil
		for _, queuedFunction in ipairs(playerEventQueue) do
			queuedFunction.Func(unpack(queuedFunction.Args))
		end

		logger:i("Player initialization queue called #" .. #playerEventQueue .. " events")
	end
end

function ga:PlayerRemoved(Player)
	--Save
	store:SavePlayerData(Player)

	local PlayerData = store:GetPlayerDataFromCache(Player.UserId)
	if PlayerData then
		if not PlayerData.PlayerTeleporting then
			ga:endSession(Player.UserId)
		else
			store.PlayerCache[Player.UserId] = nil
		end
	end
end

function ga:isPlayerReady(playerId)
	if store:GetPlayerDataFromCache(playerId) then
		return true
	else
		return false
	end
end

function ga:ProcessReceiptCallback(Info)
	--Variables
	local ProductInfo = ProductCache[Info.ProductId]

	--Cache
	if not ProductInfo then
		--Get
		pcall(function()
			ProductInfo = MKT:GetProductInfo(Info.ProductId, Enum.InfoType.Product)
			ProductCache[Info.ProductId] = ProductInfo
		end)
	end

	if ProductInfo then
		ga:addBusinessEvent(Info.PlayerId, {
			amount = Info.CurrencySpent,
			itemType = "DeveloperProduct",
			itemId = ga:filterForBusinessEvent(ProductInfo.Name),
		})
	end
end

--customGamepassInfo argument to optinaly provide our own name or price
function ga:GamepassPurchased(player, id, customGamepassInfo)
	local gamepassInfo = ProductCache[id]

	--Cache
	if not gamepassInfo then

		--Get
		gamepassInfo = MKT:GetProductInfo(id, Enum.InfoType.GamePass)
		ProductCache[id] = gamepassInfo
	end

	local amount = 0
	local itemId = "GamePass"
	if customGamepassInfo then
		amount = customGamepassInfo.PriceInRobux
		itemId = customGamepassInfo.Name
	elseif gamepassInfo then
		amount = gamepassInfo.PriceInRobux
		itemId = gamepassInfo.Name
	end

	ga:addBusinessEvent(player.UserId, {
		amount = amount or 0,
		itemType = "Gamepass",
		itemId = ga:filterForBusinessEvent(itemId),
		gamepassId = id,
	})
end

local requiredInitializationOptions = {"gameKey", "secretKey"}

function ga:initialize(options)
	threading:performTaskOnGAThread(function()
		for _, option in ipairs(requiredInitializationOptions) do
			if options[option] == nil then
				logger:e("Initialize '"..option.."' option missing")
				return
			end
		end
		if options.enableInfoLog ~= nil and options.enableInfoLog then
			ga:setEnabledInfoLog(options.enableInfoLog)
		end
		if options.enableVerboseLog ~= nil and options.enableVerboseLog then
			ga:setEnabledVerboseLog(options.enableVerboseLog)
		end
		if options.availableCustomDimensions01 ~= nil and #options.availableCustomDimensions01 > 0 then
			ga:configureAvailableCustomDimensions01(options.availableCustomDimensions01)
		end
		if options.availableCustomDimensions02 ~= nil and #options.availableCustomDimensions02 > 0 then
			ga:configureAvailableCustomDimensions02(options.availableCustomDimensions02)
		end
		if options.availableCustomDimensions03 ~= nil and #options.availableCustomDimensions03 > 0 then
			ga:configureAvailableCustomDimensions03(options.availableCustomDimensions03)
		end
		if options.availableResourceCurrencies ~= nil and #options.availableResourceCurrencies > 0 then
			ga:configureAvailableResourceCurrencies(options.availableResourceCurrencies)
		end
		if options.availableResourceItemTypes ~= nil and #options.availableResourceItemTypes > 0 then
			ga:configureAvailableResourceItemTypes(options.availableResourceItemTypes)
		end
		if options.build ~= nil and #options.build > 0 then
			ga:configureBuild(options.build)
		end
		if options.availableGamepasses ~= nil and #options.availableGamepasses > 0 then
			ga:configureAvailableGamepasses(options.availableGamepasses)
		end
		if options.enableDebugLog ~= nil then
			ga:setEnabledDebugLog(options.enableDebugLog)
		end

		if options.automaticSendBusinessEvents ~= nil then
			ga:setEnabledAutomaticSendBusinessEvents(options.automaticSendBusinessEvents)
		end
		if options.reportErrors ~= nil then
			ga:setEnabledReportErrors(options.reportErrors)
		end

		if options.useCustomUserId ~= nil then
			ga:setEnabledCustomUserId(options.useCustomUserId)
		end

		if isSdkReady({needsInitialized = true, shouldWarn = false}) then
			logger:w("SDK already initialized. Can only be called once.")
			return
		end

		local gameKey = options["gameKey"]
		local secretKey = options["secretKey"]

		if not validation:validateKeys(gameKey, secretKey) then
			logger:w("SDK failed initialize. Game key or secret key is invalid. Can only contain characters A-z 0-9, gameKey is 32 length, secretKey is 40 length. Failed keys - gameKey: " .. gameKey .. ", secretKey: " .. secretKey)
			return
		end

		events.GameKey = gameKey
		events.SecretKey = secretKey

		state.Initialized = true

		-- New Players
		Players.PlayerAdded:Connect(function(Player)
			ga:PlayerJoined(Player)
		end)

		-- Players leaving
		Players.PlayerRemoving:Connect(function(Player)
			ga:PlayerRemoved(Player)
		end)

		-- Fire for players already in game
		for _, Player in ipairs(Players:GetPlayers()) do
			coroutine.wrap(ga.PlayerJoined)(ga, Player)
		end

		for _, queuedFunction in ipairs(InitializationQueue) do
			task.spawn(queuedFunction.Func, unpack(queuedFunction.Args))
		end
		logger:i("Server initialization queue called #" .. #InitializationQueue .. " events")
		InitializationQueue = nil

		events:processEventQueue()
	end)
end


if not ReplicatedStorage:FindFirstChild("GameAnalyticsRemoteConfigs") then
	--Create
	local f = Instance.new("RemoteEvent")
	f.Name = "GameAnalyticsRemoteConfigs"
	f.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("OnPlayerReadyEvent") then
	--Create
	local f = Instance.new("BindableEvent")
	f.Name = "OnPlayerReadyEvent"
	f.Parent = ReplicatedStorage
end


task.spawn(function()
	local currentHour = math.floor(os.time() / 3600)
	ErrorDS = store:GetErrorDataStore(currentHour)

	while task.wait(ONE_HOUR_IN_SECONDS) do
		currentHour = math.floor(os.time() / 3600)
		ErrorDS = store:GetErrorDataStore(currentHour)
		errorCountCache = {}
		errorCountCacheKeys = {}
	end
end)

task.spawn(function()
	while task.wait(store.AutoSaveData) do
		for _, key in pairs(errorCountCacheKeys) do
			local errorCount = errorCountCache[key]
			local step = errorCount.currentCount - errorCount.countInDS
			errorCountCache[key].countInDS = store:IncrementErrorCount(ErrorDS, key, step)
			errorCountCache[key].currentCount = errorCountCache[key].countInDS
		end
	end
end)

local function ErrorHandler(message, trace, scriptName, player)

	local scriptNameTmp = "(null)"
	if scriptName ~= nil then
		scriptNameTmp = scriptName
	end
	local messageTmp = "(null)"
	if message ~= nil then
		messageTmp = message
	end
	local traceTmp = "(null)"
	if trace ~= nil then
		traceTmp = trace
	end
	local m = scriptNameTmp .. ": message=" .. messageTmp .. ", trace=" .. traceTmp
	if #m > 8192 then
		m = string.sub(m, 1, 8192)
	end

	local userId = nil
	if player then
		userId = player.UserId
		m = m:gsub(player.Name, "[LocalPlayer]") -- so we don't flood the same errors with different player names
	end

	local key = m
	if #key > 50 then
		key = string.sub(key, 1, 50)
	end

	if errorCountCache[key] == nil then
		errorCountCacheKeys[#errorCountCacheKeys + 1] = key
		errorCountCache[key] = {}
		errorCountCache[key].countInDS = 0
		errorCountCache[key].currentCount = 0
	end

	-- don't report error if limit has been exceeded
	if errorCountCache[key].currentCount > MaxErrorsPerHour then
		return
	end

	ga:addErrorEvent(userId, {
		severity = ga.EGAErrorSeverity.error,
		message = m,
	})

	-- increment error count
	errorCountCache[key].currentCount = errorCountCache[key].currentCount + 1
end

local function ErrorHandlerFromServer(message, trace, Script)
	--Validate
	if not state.ReportErrors then
		return
	end

	if not Script then -- don't remember if this check is necessary but must have added it for a reason
		return
	end

	local scriptName = nil
	local ok, _ = pcall(function()
		scriptName = Script:GetFullName() -- CoreGui.RobloxGui.Modules.PlayerList error, can't get name because of security permission
	end)
	if not ok then
		return
	end

	return ErrorHandler(message, trace, scriptName)
end

local function ErrorHandlerFromClient(message, trace, scriptName, player)
	--Validate
	if not state.ReportErrors then
		return
	end

	return ErrorHandler(message, trace, scriptName, player)
end

--Error Logging
ScriptContext.Error:Connect(ErrorHandlerFromServer)
if not ReplicatedStorage:FindFirstChild("GameAnalyticsError") then
	--Create
	local f = Instance.new("RemoteEvent")
	f.Name = "GameAnalyticsError"
	f.Parent = ReplicatedStorage
end

ReplicatedStorage.GameAnalyticsError.OnServerEvent:Connect(function(player, message, trace, scriptName)
	ErrorHandlerFromClient(message, trace, scriptName, player)
end)


--Record Gamepasses.
MKT.PromptGamePassPurchaseFinished:Connect(function(Player, ID, Purchased)

	--Validate
	if not state.AutomaticSendBusinessEvents or not Purchased then
		return
	end

	ga:GamepassPurchased(Player, ID)
end)

return ga
