local events = {
	ProcessEventsInterval = 8,
	GameKey = "",
	SecretKey = "",
	Build = "",
	_availableResourceCurrencies = {},
	_availableResourceItemTypes = {},
}

local store = require(script.Parent.Store)
local logger = require(script.Parent.Logger)
local version = require(script.Parent.Version)
local validation = require(script.Parent.Validation)
local threading = require(script.Parent.Threading)
local http_api = require(script.Parent.HttpApi)
local utilities = require(script.Parent.Utilities)
local GAResourceFlowType = require(script.Parent.GAResourceFlowType)
local GAProgressionStatus = require(script.Parent.GAProgressionStatus)
local GAErrorSeverity = require(script.Parent.GAErrorSeverity)
local HTTP = game:GetService("HttpService")

local CategorySessionStart = "user"
local CategorySessionEnd = "session_end"
local CategoryBusiness = "business"
local CategoryResource = "resource"
local CategoryProgression = "progression"
local CategoryDesign = "design"
local CategoryError = "error"
local CategorySdkError = "sdk_error"
local MAX_EVENTS_TO_SEND_IN_ONE_BATCH = 500
local MAX_AGGREGATED_EVENTS = 2000

local function addDimensionsToEvent(playerId, eventData)
	if not eventData or not playerId then
		return
	end

	local PlayerData = store:GetPlayerDataFromCache(playerId)

	-- add to dict (if not nil)
	if PlayerData and PlayerData.CurrentCustomDimension01 and #PlayerData.CurrentCustomDimension01 > 0 then
		eventData["custom_01"] = PlayerData.CurrentCustomDimension01
	end

	if PlayerData and PlayerData.CurrentCustomDimension02 and #PlayerData.CurrentCustomDimension02 > 0 then
		eventData["custom_02"] = PlayerData.CurrentCustomDimension02
	end

	if PlayerData and PlayerData.CurrentCustomDimension03 and #PlayerData.CurrentCustomDimension03 > 0 then
		eventData["custom_03"] = PlayerData.CurrentCustomDimension03
	end
end

local function getClientTsAdjusted(playerId)
	if not playerId then
		return os.time()
	end

	local PlayerData = store:GetPlayerDataFromCache(playerId)
	local clientTs = os.time()
	local clientTsAdjustedInteger = clientTs + PlayerData.ClientServerTimeOffset
	if validation:validateClientTs(clientTsAdjustedInteger) then
		return clientTsAdjustedInteger
	else
		return clientTs
	end
end

local DUMMY_SESSION_ID = HTTP:GenerateGUID(false):lower()

local function recursiveToString(object)
	if typeof(object) == "table" then
		local str = "{\n"
		for i,v in pairs(object) do
			if typeof(i) == "string" then
				str = str .. i .. " = "
			else
				str = str .. "[" .. tostring(i) .. "] = "
			end

			str = str .. tostring(v) .. ",\n"
		end
		str = str .. "}"
		return str
	else
		return tostring(object)
	end
end

local function Length(Table)
	local counter = 0
	for _, v in pairs(Table) do
		counter =counter + 1
	end
	return counter
end

local function getEventAnnotations(playerId)
	local PlayerData
	local id

	if playerId then
		id = playerId
		PlayerData = store:GetPlayerDataFromCache(playerId)
	else
		id = "DummyId"
		PlayerData = {
			OS = "uwp_desktop 0.0.0",
			Platform = "uwp_desktop",
			SessionID = DUMMY_SESSION_ID,
			Sessions = 1,
			CustomUserId = "Server"
		}
	end

	local annotations = {
		-- ---- REQUIRED ----
		-- collector event API version
		["v"] = 2,
		-- User identifier
		["user_id"] = tostring(id) .. PlayerData.CustomUserId,
		-- Client Timestamp (the adjusted timestamp)
		["client_ts"] = getClientTsAdjusted(playerId),
		-- SDK version
		["sdk_version"] = "roblox " .. version.SdkVersion,
		-- Operation system version
		["os_version"] = PlayerData.OS,
		-- Device make (hardcoded to apple)
		["manufacturer"] = "unknown",
		-- Device version
		["device"] = "unknown",
		-- Platform (operating system)
		["platform"] = PlayerData.Platform,
		-- Session identifier
		["session_id"] = PlayerData.SessionID,
		-- Session number
		["session_num"] = PlayerData.Sessions
	}

	if not utilities:isStringNullOrEmpty(PlayerData.CountryCode) then
		annotations["country_code"] = PlayerData.CountryCode
	else
		annotations["country_code"] = "unknown"
	end

	if validation:validateBuild(events.Build) then
		annotations["build"] = events.Build
	end

	if PlayerData.Configurations and Length(PlayerData.Configurations) > 0 then
		annotations["configurations"] = PlayerData.Configurations
	end

	if not utilities:isStringNullOrEmpty(PlayerData.AbId) then
		annotations["ab_id"] = PlayerData.AbId
	end

	if not utilities:isStringNullOrEmpty(PlayerData.AbVariantId) then
		annotations["ab_variant_id"] = PlayerData.AbVariantId
	end

	return annotations
end

local function addEventToStore(playerId, eventData)
	-- Get default annotations
	local ev = getEventAnnotations(playerId)

	-- Merge with eventData
	for k in pairs(eventData) do
		ev[k] = eventData[k]
	end

	-- Create json string representation
	local json = HTTP:JSONEncode(ev)

	-- output if VERBOSE LOG enabled
	logger:ii("Event added to queue: " .. json)

	-- Add to store
	store.EventsQueue[#store.EventsQueue + 1] = ev
end

local function dequeueMaxEvents()
	if #store.EventsQueue <= MAX_EVENTS_TO_SEND_IN_ONE_BATCH then
		local eventsQueue = store.EventsQueue
		store.EventsQueue = {}
		return eventsQueue
	else
		logger:w(("More than %d events queued! Sending %d."):format(MAX_EVENTS_TO_SEND_IN_ONE_BATCH, MAX_EVENTS_TO_SEND_IN_ONE_BATCH))

		if #store.EventsQueue > MAX_AGGREGATED_EVENTS then
			logger:w(("DROPPING EVENTS: More than %d events queued!"):format(MAX_AGGREGATED_EVENTS))
		end

		-- Expensive operation to get ordered events cleared out (O(n))
		local eventsQueue = table.create(MAX_EVENTS_TO_SEND_IN_ONE_BATCH)
		for i = 1, MAX_EVENTS_TO_SEND_IN_ONE_BATCH do
			eventsQueue[i] = store.EventsQueue[i]
		end

		-- Shift everything down and overwrite old events
		local eventCount = #store.EventsQueue
		for i = 1, math.min(MAX_AGGREGATED_EVENTS, eventCount) do
			store.EventsQueue[i] = store.EventsQueue[i + MAX_EVENTS_TO_SEND_IN_ONE_BATCH]
		end

		-- Clear additional events
		for i = MAX_AGGREGATED_EVENTS + 1, eventCount do
			store.EventsQueue[i] = nil
		end

		return eventsQueue
	end
end

local function processEvents()
	local queue = dequeueMaxEvents()

	if #queue == 0 then
		logger:i("Event queue: No events to send")
		return
	end

	-- Log
	logger:i("Event queue: Sending " .. tostring(#queue) .. " events.")

	local eventsResult = http_api:sendEventsInArray(events.GameKey, events.SecretKey, queue)
	local statusCode = eventsResult.statusCode
	local responseBody = eventsResult.body

	if statusCode == http_api.EGAHTTPApiResponse.Ok and responseBody then
		logger:i("Event queue: " .. tostring(#queue) .. " events sent.")
	else
		if statusCode == http_api.EGAHTTPApiResponse.NoResponse then
			logger:w("Event queue: Failed to send events to collector - Retrying next time")
			for _, e in pairs(queue) do
				if #store.EventsQueue < MAX_AGGREGATED_EVENTS then
					store.EventsQueue[#store.EventsQueue + 1] = e
				else
					break
				end
			end
		else
			if statusCode == http_api.EGAHTTPApiResponse.BadRequest and responseBody then
				logger:w("Event queue: " .. tostring(#queue) .. " events sent. " .. tostring(#responseBody) .. " events failed GA server validation.")
			else
				logger:w("Event queue: Failed to send events.")
			end
		end
	end
end

function events:processEventQueue()
	processEvents()
	threading:scheduleTimer(events.ProcessEventsInterval, function()
		events:processEventQueue()
	end)
end

function events:setBuild(build)
	if not validation:validateBuild(build) then
		logger:w("Validation fail - configure build: Cannot be null, empty or above 32 length. String: " .. build)
		return
	end

	self.Build = build
	logger:i("Set build version: " .. build)
end

function events:setAvailableResourceCurrencies(availableResourceCurrencies)
	if not validation:validateResourceCurrencies(availableResourceCurrencies) then
		return
	end

	self._availableResourceCurrencies = availableResourceCurrencies
	logger:i("Set available resource currencies: (" .. table.concat(availableResourceCurrencies, ", ") .. ")")
end

function events:setAvailableResourceItemTypes(availableResourceItemTypes)
	if not validation:validateResourceCurrencies(availableResourceItemTypes) then
		return
	end

	self._availableResourceItemTypes = availableResourceItemTypes
	logger:i("Set available resource item types: (" .. table.concat(availableResourceItemTypes, ", ") .. ")")
end

function events:addSessionStartEvent(playerId, teleportData)
	local PlayerData = store:GetPlayerDataFromCache(playerId)

	if teleportData then
		PlayerData.Sessions = teleportData.Sessions
	else
		local eventDict = {}

		-- Event specific data
		eventDict["category"] = CategorySessionStart

		-- Increment session number  and persist
		PlayerData.Sessions = PlayerData.Sessions + 1

		--  Add custom dimensions
		addDimensionsToEvent(playerId, eventDict)

		-- Add to store
		addEventToStore(playerId, eventDict)

		logger:i("Add SESSION START event")

		processEvents()
	end
end

function events:addSessionEndEvent(playerId)
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	local session_start_ts = PlayerData.SessionStart
	local client_ts_adjusted = getClientTsAdjusted(playerId)
	local sessionLength = 0

	if client_ts_adjusted ~= nil and session_start_ts ~= nil then
		sessionLength = client_ts_adjusted - session_start_ts
	end

	if sessionLength < 0 then
		-- Should never happen.
		-- Could be because of edge cases regarding time altering on device.
		logger:w("Session length was calculated to be less then 0. Should not be possible. Resetting to 0.")
		sessionLength = 0
	end

	-- Event specific data
	local eventDict = {}
	eventDict["category"] = CategorySessionEnd
	eventDict["length"] = sessionLength

	-- Add custom dimensions
	addDimensionsToEvent(playerId, eventDict)

	-- Add to store
	addEventToStore(playerId, eventDict)
	PlayerData.SessionStart = 0

	logger:i("Add SESSION END event.")

	processEvents()
end

function events:addBusinessEvent(playerId, currency, amount, itemType, itemId, cartType)
	-- Validate event params
	if not validation:validateBusinessEvent(currency, amount, cartType, itemType, itemId) then
		-- TODO: add sdk error event
		return
	end

	-- Create empty eventData
	local eventDict = {}

	-- Increment transaction number and persist
	local PlayerData = store:GetPlayerDataFromCache(playerId)
	PlayerData.Transactions = PlayerData.Transactions + 1

	-- Required
	eventDict["event_id"] = itemType .. ":" .. itemId
	eventDict["category"] = CategoryBusiness
	eventDict["currency"] = currency
	eventDict["amount"] = amount
	eventDict["transaction_num"] = PlayerData.Transactions

	-- Optional
	if not utilities:isStringNullOrEmpty(cartType) then
		eventDict["cart_type"] = cartType
	end

	-- Add custom dimensions
	addDimensionsToEvent(playerId, eventDict)

	logger:i("Add BUSINESS event: {currency:" .. currency .. ", amount:" .. tostring(amount) .. ", itemType:" .. itemType .. ", itemId:" .. itemId .. ", cartType:" .. cartType .. "}")

	-- Send to store
	addEventToStore(playerId, eventDict)
end

function events:addResourceEvent(playerId, flowType, currency, amount, itemType, itemId)
	-- Validate event params
	if not validation:validateResourceEvent(GAResourceFlowType, flowType, currency, amount, itemType, itemId, self._availableResourceCurrencies, self._availableResourceItemTypes) then
		-- TODO: add sdk error event
		return
	end

	-- If flow type is sink reverse amount
	if flowType == GAResourceFlowType.Sink then
		amount = (-1 * amount)
	end

	-- Create empty eventData
	local eventDict = {}

	-- insert event specific values
	local flowTypeString = GAResourceFlowType[flowType]
	eventDict["event_id"] = flowTypeString .. ":" .. currency .. ":" .. itemType .. ":" .. itemId
	eventDict["category"] = CategoryResource
	eventDict["amount"] = amount

	-- Add custom dimensions
	addDimensionsToEvent(playerId, eventDict)

	logger:i("Add RESOURCE event: {currency:" .. currency .. ", amount:" .. tostring(amount) .. ", itemType:" .. itemType .. ", itemId:" .. itemId .. "}")

	-- Send to store
	addEventToStore(playerId, eventDict)
end

function events:addProgressionEvent(playerId, progressionStatus, progression01, progression02, progression03, score)
	-- Validate event params
	if not validation:validateProgressionEvent(GAProgressionStatus, progressionStatus, progression01, progression02, progression03) then
		-- TODO: add sdk error event
		return
	end

	-- Create empty eventData
	local eventDict = {}

	-- Progression identifier
	local progressionIdentifier
	if utilities:isStringNullOrEmpty(progression02) then
		progressionIdentifier = progression01
	elseif utilities:isStringNullOrEmpty(progression03) then
		progressionIdentifier = progression01 .. ":" .. progression02
	else
		progressionIdentifier = progression01 .. ":" .. progression02 .. ":" .. progression03
	end

	local statusString = GAProgressionStatus[progressionStatus]

	-- Append event specifics
	eventDict["category"] = CategoryProgression
	eventDict["event_id"] = statusString .. ":" .. progressionIdentifier

	-- Attempt
	local attempt_num = 0

	-- Add score if specified and status is not start
	if score ~= nil and progressionStatus ~= GAProgressionStatus.Start then
		eventDict["score"] = score
	end

	local PlayerData = store:GetPlayerDataFromCache(playerId)

	-- Count attempts on each progression fail and persist
	if progressionStatus == GAProgressionStatus.Fail then
		-- Increment attempt number
		local progressionTries = PlayerData.ProgressionTries[progressionIdentifier] or 0
		PlayerData.ProgressionTries[progressionIdentifier] = progressionTries + 1
	end

	-- increment and add attempt_num on complete and delete persisted
	if progressionStatus == GAProgressionStatus.Complete then
		-- Increment attempt number
		local progressionTries = PlayerData.ProgressionTries[progressionIdentifier] or 0
		PlayerData.ProgressionTries[progressionIdentifier] = progressionTries + 1

		-- Add to event
		attempt_num = PlayerData.ProgressionTries[progressionIdentifier]
		eventDict["attempt_num"] = attempt_num

		-- Clear
		PlayerData.ProgressionTries[progressionIdentifier] = 0
	end

	-- Add custom dimensions
	addDimensionsToEvent(playerId, eventDict)

	local progression02String = ""
	if not utilities:isStringNullOrEmpty(progression02) then
		progression02String = progression02
	end

	local progression03String = ""
	if not utilities:isStringNullOrEmpty(progression03) then
		progression03String = progression03
	end

	logger:i("Add PROGRESSION event: {status:" .. statusString .. ", progression01:" .. progression01 .. ", progression02:" .. progression02String .. ", progression03:" .. progression03String .. ", score:" .. tostring(score) .. ", attempt:" .. tostring(attempt_num) .. "}")

	-- Send to store
	addEventToStore(playerId, eventDict)
end

function events:addDesignEvent(playerId, eventId, value)
	-- Validate
	if not validation:validateDesignEvent(eventId) then
		-- TODO: add sdk error event
		return
	end

	-- Create empty eventData
	local eventData = {}

	-- Append event specifics
	eventData["category"] = CategoryDesign
	eventData["event_id"] = eventId

	if value ~= nil then
		eventData["value"] = value
	end

	-- Add custom dimensions
	addDimensionsToEvent(playerId, eventData)

	logger:i("Add DESIGN event: {eventId:" .. eventId .. ", value:" .. tostring(value) .. "}")

	-- Send to store
	addEventToStore(playerId, eventData)
end

function events:addErrorEvent(playerId, severity, message)
	-- Validate
	if not validation:validateErrorEvent(GAErrorSeverity, severity, message) then
		-- TODO: add sdk error event
		return
	end

	-- Create empty eventData
	local eventData = {}

	local severityString = GAErrorSeverity[severity]

	eventData["category"] = CategoryError
	eventData["severity"] = severityString
	eventData["message"] = message

	-- Add custom dimensions
	addDimensionsToEvent(playerId, eventData)

	local messageString = ""
	if not utilities:isStringNullOrEmpty(message) then
		messageString = message
	end

	logger:i("Add ERROR event: {severity:" .. severityString .. ", message:" .. messageString .. "}")

	-- Send to store
	addEventToStore(playerId, eventData)
end

function events:addSdkErrorEvent(playerId, category, area, action, parameter, reason)
	-- Create empty eventData
	local eventData = {}

	eventData["category"] = CategorySdkError
	eventData["error_category"] = category
	eventData["error_area"] = area
	eventData["error_action"] = action

	if not utilities:isStringNullOrEmpty(parameter) then
		eventData["error_parameter"] = parameter
	end

	if not utilities:isStringNullOrEmpty(reason) then
		eventData["reason"] = reason
	end

	logger:i("Add SDK ERROR event: {error_category:" .. category .. ", error_area:" .. area .. ", error_action:" .. action .. "}")

	-- Send to store
	addEventToStore(playerId, eventData)
end

return events
