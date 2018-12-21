local events = {
    ProcessEventsInterval = 8
}

local store = require(script.Parent.Store)
local logger = require(script.Parent.Logger)
local version = require(script.Parent.Version)
local validation = require(script.Parent.Validation)
local settings = require(script.Parent.Settings)
local threading = require(script.Parent.Threading)
local http_api = require(script.Parent.HttpApi)
local utilities = require(script.Parent.Utilities)
local HTTP = game:GetService("HttpService")

local CategorySessionStart = "user"
local CategorySessionEnd = "session_end"
local CategoryBusiness = "business"
local CategoryResource = "resource"
local CategoryProgression = "progression"
local CategoryDesign = "design"
local CategoryError = "error"

local function addDimensionsToEvent(playerId, eventData)
    if not eventData then
        return
    end

    local PlayerData = store.PlayerCache[playerId]

    -- add to dict (if not nil)
    if PlayerData.CurrentCustomDimension01 and #PlayerData.CurrentCustomDimension01 > 0 then
        eventData["custom_01"] = PlayerData.CurrentCustomDimension01
    end
    if PlayerData.CurrentCustomDimension02 and #PlayerData.CurrentCustomDimension02 > 0 then
        eventData["custom_02"] = PlayerData.CurrentCustomDimension02
    end
    if PlayerData.CurrentCustomDimension03 and #PlayerData.CurrentCustomDimension03 > 0 then
        eventData["custom_03"] = PlayerData.CurrentCustomDimension03
    end
end

local function getClientTsAdjusted(playerId)
    if not playerId then
        return os.time()
    end
    local PlayerData = store.PlayerCache[playerId]
    local clientTs = os.time()
    local clientTsAdjustedInteger = clientTs + PlayerData.ClientServerTimeOffset
    if validation:validateClientTs(clientTsAdjustedInteger) then
        return clientTsAdjustedInteger;
    else
        return clientTs
    end
end

local function getEventAnnotations(playerId)
    local PlayerData
    local id

    if playerId then
        id = playerId
        PlayerData = store.PlayerCache[playerId]
    else
        id = "DummyId"
        PlayerData = {
            OS = "uwp_desktop 0.0.0",
            Platform = "uwp_desktop",
            SessionID = 1,
            Sessions = 1
        }
    end

    local annotations = {
        -- ---- REQUIRED ----
        -- collector event API version
        ["v"] = 2,
        -- User identifier
        ["user_id"] = tostring(id),
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

    if validation:validateBuild(settings.Build) then
        annotations["build"] = settings.Build
    end

    return annotations
end

local function addEventToStore(playerId, eventData)
    -- Get default annotations
    local ev = getEventAnnotations(playerId)

    -- Merge with eventData
    for k,_ in pairs(eventData) do
        ev[k] = eventData[k]
    end

    -- Create json string representation
    local json = HTTP:JSONEncode(ev)

    -- output if VERBOSE LOG enabled
    logger:ii("Event added to queue: " .. json)

    -- Add to store
    table.insert(store.EventsQueue, ev)
end

--Misc Functions
local function cloneTable(t)
    local c = {}
    for i,v in pairs(t) do
        c[i] = typeof(v) == "table" and cloneTable(v) or v
    end
    return c
end

local function processEvents()
    local queue = cloneTable(store.EventsQueue)
    store.EventsQueue = {}

    if #queue == 0 then
        logger:i("Event queue: No events to send")
        return
    end

    -- Log
    logger:i("Event queue: Sending " .. tostring(#queue) .. " events.")

    local eventsResult = http_api:sendEventsInArray(settings.GameKey, settings.SecretKey, queue)
    local statusCode = eventsResult.statusCode
    local responseBody = eventsResult.body

    if statusCode == http_api.EGAHTTPApiResponse.Ok and responseBody then
        logger:i("Event queue: " .. tostring(#queue) .. " events sent.")
    else
        if statusCode == http_api.EGAHTTPApiResponse.NoResponse then
            logger:w("Event queue: Failed to send events to collector - Retrying next time")
            for _,e in pairs(queue) do
                if #store.EventsQueue < 500 then
                    table.insert(store.EventsQueue, e)
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

local function resourceFlowTypeString(flowType)
    if flowType == 1 then
        return "Source"
    elseif flowType == 2 then
        return "Sink"
    else
        return ""
    end
end

local function progressionStatusString(progressionStatus)
    if progressionStatus == 1 then
        return "Start"
    elseif progressionStatus == 2 then
        return "Complete"
    elseif progressionStatus == 3 then
        return "Fail"
    else
        return ""
    end
end

local function errorSeverityString(severity)
    if severity == 1 then
        return "debug"
    elseif severity == 2 then
        return "info"
    elseif severity == 3 then
        return "warning"
    elseif severity == 4 then
        return "error"
    elseif severity == 5 then
        return "critical"
    else
        return ""
    end
end

function events:processEventQueue()
    processEvents()
    threading:scheduleTimer(events.ProcessEventsInterval, function()
        events:processEventQueue()
    end)
end

function events:addSessionStartEvent(playerId)
    local eventDict = {}

    -- Event specific data
    eventDict["category"] = CategorySessionStart

    local PlayerData = store.PlayerCache[playerId]

    -- Increment session number  and persist
    PlayerData.Sessions = PlayerData.Sessions + 1

    --  Add custom dimensions
    addDimensionsToEvent(playerId, eventDict)

    -- Add to store
    addEventToStore(playerId, eventDict)

    logger:i("Add SESSION START event")

    processEvents()
end

function events:addSessionEndEvent(playerId)
    local PlayerData = store.PlayerCache[playerId]
    local session_start_ts = PlayerData.SessionStart
    local client_ts_adjusted = getClientTsAdjusted(playerId)
    local sessionLength = client_ts_adjusted - session_start_ts

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
    local PlayerData = store.PlayerCache[playerId]
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
    if not validation:validateResourceEvent(flowType, currency, amount, itemType, itemId, settings.AvailableResourceCurrencies, settings.AvailableResourceItemTypes) then
        -- TODO: add sdk error event
        return
    end

    -- If flow type is sink reverse amount
    if flowType == 2 then
        amount = (-1 * amount)
    end

    -- Create empty eventData
    local eventDict = {}

    -- insert event specific values
    local flowTypeString = resourceFlowTypeString(flowType)
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
    if not validation:validateProgressionEvent(progressionStatus, progression01, progression02, progression03) then
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

    local statusString = progressionStatusString(progressionStatus)

    -- Append event specifics
    eventDict["category"] = CategoryProgression
    eventDict["event_id"] = statusString .. ":" .. progressionIdentifier

    -- Attempt
    local attempt_num = 0

    -- Add score if specified and status is not start
    if score ~= nil and progressionStatus ~= 1 then
        eventDict["score"] = score
    end

    local PlayerData = store.PlayerCache[playerId]

    -- Count attempts on each progression fail and persist
    if progressionStatus == 3 then
        -- Increment attempt number
        local progressionTries = PlayerData.ProgressionTries[progressionIdentifier] or 0
        PlayerData.ProgressionTries[progressionIdentifier] = progressionTries + 1
    end

    -- increment and add attempt_num on complete and delete persisted
    if progressionStatus == 2 then
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

    logger:i("Add PROGRESSION event: {status:" .. statusString .. ", progression01:" .. progression01 .. ", progression02:" .. progression02 .. ", progression03:" .. progression03 .. ", score:" .. tostring(score) .. ", attempt:" .. tostring(attempt_num) .. "}")

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
    if not validation:validateErrorEvent(severity, message) then
        -- TODO: add sdk error event
        return
    end

    -- Create empty eventData
    local eventData = {}

    local severityString = errorSeverityString(severity)

    eventData["category"] = CategoryError
    eventData["severity"] = severityString
    eventData["message"] = message

    -- Add custom dimensions
    addDimensionsToEvent(playerId, eventData)

    logger:i("Add ERROR event: {severity:" .. severityString .. ", message:" .. message .. "}")

    -- Send to store
    addEventToStore(playerId, eventData)
end

return events
