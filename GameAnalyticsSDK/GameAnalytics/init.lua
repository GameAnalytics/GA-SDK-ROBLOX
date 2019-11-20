local GAResourceFlowType = require(script.GAResourceFlowType)
local GAProgressionStatus = require(script.GAProgressionStatus)
local GAErrorSeverity = require(script.GAErrorSeverity)

local ga = {
    EGAResourceFlowType = GAResourceFlowType,
    EGAProgressionStatus = GAProgressionStatus,
    EGAErrorSeverity = GAErrorSeverity
}

local logger = require(script.Logger)
local threading = require(script.Threading)
local state = require(script.State)
local validation = require(script.Validation)
local store = require(script.Store)
local events = require(script.Events)
local Players = game:GetService("Players")
local MKT = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Postie = require(ReplicatedStorage.Postie)
local ProductCache = {}
local OnPlayerReadyEvent


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
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
            logger:w("Available custom dimensions must be set before SDK is initialized")
            return
        end

        state:setAvailableCustomDimensions01(customDimensions)
    end)
end

function ga:configureAvailableCustomDimensions02(customDimensions)
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
            logger:w("Available custom dimensions must be set before SDK is initialized")
            return
        end

        state:setAvailableCustomDimensions02(customDimensions)
    end)
end

function ga:configureAvailableCustomDimensions03(customDimensions)
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
            logger:w("Available custom dimensions must be set before SDK is initialized")
            return
        end

        state:setAvailableCustomDimensions03(customDimensions)
    end)
end

function ga:configureAvailableResourceCurrencies(resourceCurrencies)
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
            logger:w("Available resource currencies must be set before SDK is initialized")
            return
        end

        events:setAvailableResourceCurrencies(resourceCurrencies)
    end)
end

function ga:configureAvailableResourceItemTypes(resourceItemTypes)
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
            logger:w("Available resource item types must be set before SDK is initialized")
            return
        end

        events:setAvailableResourceItemTypes(resourceItemTypes)
    end)
end

function ga:configureBuild(build)
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
            logger:w("Build version must be set before SDK is initialized.")
            return
        end

        events:setBuild(build)
    end)
end

function ga:initialize(options)
    threading:performTaskOnGAThread(function()
        if isSdkReady({needsInitialized=true, shouldWarn=false}) then
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
        events:processEventQueue()

    end)
end

function ga:startNewSession(player, teleportData)
    threading:performTaskOnGAThread(function()
        if not state:isEventSubmissionEnabled() then
            return
        end
        if not state.Initialized then
            logger:w("Cannot start new session. SDK is not initialized yet.")
            return
        end

        state:startNewSession(player, teleportData)
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not add business event"}) then
            return
        end

        -- Send to events
        local amount = options["amount"] or 0
        local itemType = options["itemType"] or ""
        local itemId = options["itemId"] or ""
        local cartType = options["cartType"] or ""
        local USDSpent = math.floor((amount * 0.7) * 0.35)

        events:addBusinessEvent(playerId, "USD", USDSpent, itemType, itemId, cartType)
    end)
end

function ga:addResourceEvent(playerId, options)
    threading:performTaskOnGAThread(function()
        if not state:isEventSubmissionEnabled() then
            return
        end
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not add resource event"}) then
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not add progression event"}) then
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not add design event"}) then
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not add error event"}) then
            return
        end

        -- Send to events
        local severity = options["severity"] or 0
        local message = options["message"] or ""

        events:addErrorEvent(playerId, severity, message)
    end)
end

function ga:setEnabledDebugLog(flag)
    threading:performTaskOnGAThread(function()
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
    end)
end

function ga:setEnabledInfoLog(flag)
    threading:performTaskOnGAThread(function()
        if flag then
            logger:setInfoLog(flag)
            logger:i("Info logging enabled")
        else
            logger:i("Info logging disabled")
            logger:setInfoLog(flag)
        end
    end)
end

function ga:setEnabledVerboseLog(flag)
    threading:performTaskOnGAThread(function()
        if flag then
            logger:setVerboseLog(flag)
            logger:ii("Verbose logging enabled")
        else
            logger:ii("Verbose logging disabled")
            logger:setVerboseLog(flag)
        end
    end)
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not set custom01 dimension"}) then
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not set custom02 dimension"}) then
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
        if not isSdkReady({playerId=playerId, needsInitialized=true, shouldWarn=true, message="Could not set custom03 dimension"}) then
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

function ga:setEnabledAutomaticSendBusinessEvents(flag)
    threading:performTaskOnGAThread(function()
        state.AutomaticSendBusinessEvents = flag
    end)
end

function ga:addGameAnalyticsTeleportData(playerIds, teleportData)
    local gameAnalyticsTeleportData = {}
    for index = 1, #playerIds do
        local playerId = playerIds[index]
        local PlayerData = store.PlayerCache[playerId]
        PlayerData.PlayerTeleporting = true
        local data = {
            ["SessionID"] = PlayerData.SessionID,
            ["Sessions"] = PlayerData.Sessions,
            ["SessionStart"] = PlayerData.SessionStart
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

function ga:PlayerJoined(Player, teleportData)
    if store.PlayerCache[Player.UserId] then
        return
    end

    --Variables
    local PlayerData = store:GetPlayerData(Player)

    local PlayerPlatform = "unknown"
    local isSuccessful, platform = Postie.InvokeClient("getPlatform", Player, 5)
    if isSuccessful then
        PlayerPlatform = platform
    end

    --Fill Data
    for key, value in pairs(store.BasePlayerData) do
        PlayerData[key] = PlayerData[key] or value
    end

    store.PlayerCache[Player.UserId] = PlayerData

    PlayerData.Platform = (PlayerPlatform == "Console" and "uwp_console") or (PlayerPlatform == "Mobile" and "uwp_mobile") or (PlayerPlatform == "Desktop" and "uwp_desktop") or ("uwp_desktop")
    PlayerData.OS = PlayerData.Platform .. " 0.0.0"

    ga:startNewSession(Player, teleportData)

    OnPlayerReadyEvent = OnPlayerReadyEvent or game:GetService("ReplicatedStorage"):WaitForChild("OnPlayerReadyEvent")
    OnPlayerReadyEvent:Fire(Player)

    --Autosave
    spawn(function()

        --Loop
        while true do

            --Delay
            wait(store.AutoSaveData)

            --Validate
            if (not Player) or (Player.Parent ~= Players) then return end

            --Save
            store:SavePlayerData(Player)
        end
    end)
end

function ga:PlayerRemoved(Player)
    --Save
    store:SavePlayerData(Player)

    local PlayerData = store.PlayerCache[Player.UserId]
    if PlayerData and not PlayerData.PlayerTeleporting then
        ga:endSession(Player.UserId)
    end
end

function ga:isPlayerReady(playerId)
    if store.PlayerCache[playerId] then
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
        ProductInfo = MKT:GetProductInfo(Info.ProductId, Enum.InfoType.Product)
        ProductCache[Info.ProductId] = ProductInfo
    end

    ga:addBusinessEvent(Info.PlayerId, {
        amount = Info.CurrencySpent,
        itemType = "DeveloperProduct",
        itemId = ga:filterForBusinessEvent(ProductInfo.Name)
    })
end

return ga
