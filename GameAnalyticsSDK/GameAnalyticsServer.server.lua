--[[

    NOTE: This script should be in game.ServerScriptService

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--Validate
if not script:IsDescendantOf(game:GetService("ServerScriptService")) then
    error("GameAnalytics: Disabled server. GameAnalyticsServer has to be located in game.ServerScriptService.")
    return
end

-- if not ReplicatedStorage:FindFirstChild("GameAnalyticsSendMessage") then
--     --Create
--     local f = Instance.new("RemoteEvent")
--     f.Name = "GameAnalyticsSendMessage"
--     f.Parent = ReplicatedStorage
-- end

if not ReplicatedStorage:FindFirstChild("GameAnalyticsCommandCenter") then
    --Create
    local f = Instance.new("RemoteEvent")
    f.Name = "GameAnalyticsCommandCenter"
    f.Parent = ReplicatedStorage
end

--Modules
local GameAnalytics = require(ServerStorage.GameAnalytics)
local store = require(ServerStorage.GameAnalytics.Store)
local state = require(ServerStorage.GameAnalytics.State)
local LS = game:GetService("LogService")
local MKT = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProductCache = {}
local ONE_HOUR_IN_SECONDS = 3600
local MaxErrorsPerHour = 10
local ErrorDS = {}
local errorCountCache = {}
local errorCountCacheKeys = {}

spawn(function()
    local currentHour = math.floor(os.time()/3600)
    ErrorDS = store:GetErrorDataStore(currentHour)

    while wait(ONE_HOUR_IN_SECONDS) do
        currentHour = math.floor(os.time()/3600)
        ErrorDS = store:GetErrorDataStore(currentHour)
        errorCountCache = {}
        errorCountCacheKeys = {}
    end
end)

spawn(function()
    while wait(store.AutoSaveData) do
        for _, key in pairs(errorCountCacheKeys) do
            local errorCount = errorCountCache[key]
            local step = errorCount.currentCount - errorCount.countInDS
            errorCountCache[key].countInDS = store:IncrementErrorCount(ErrorDS, key, step)
            errorCountCache[key].currentCount = errorCountCache[key].countInDS
        end
    end
end)

--Error Logging
LS.MessageOut:Connect(function(message, messageType)

    --Validate
    if not state.ReportErrors then
        return
    end
    if messageType ~= Enum.MessageType.MessageError then
        return
    end

    local m = message
    if #m > 8192 then
        m = string.sub(m, 1, 8192)
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

    --Report (use nil for playerId as real player id is not available)
    GameAnalytics:addErrorEvent(nil, {
        severity = GameAnalytics.EGAErrorSeverity.Error,
        message = m
    })

    -- increment error count
    errorCountCache[key].currentCount = errorCountCache[key].currentCount + 1
end)

--Record Gamepasses. NOTE: This doesn't record gamepass purchases if a player buys it from the website
MKT.PromptGamePassPurchaseFinished:Connect(function(Player, ID, Purchased)

    --Validate
    if not state.AutomaticSendBusinessEvents then
        return
    end

    --Validate
    if not Purchased then return end

    --Variables
    local GamepassInfo = ProductCache[ID]

    --Cache
    if not GamepassInfo then

        --Get
        GamepassInfo = MKT:GetProductInfo(ID, Enum.InfoType.GamePass)
        ProductCache[ID] = GamepassInfo
    end

    GameAnalytics:addBusinessEvent(Player.UserId, {
        amount = GamepassInfo.PriceInRobux,
        itemType = "Gamepass",
        itemId = GamepassInfo.Name
    })
end)

-- Fire for players already in game
for _, Player in pairs(Players:GetPlayers()) do
    GameAnalytics:PlayerJoined(Player)
end

-- New Players
Players.PlayerAdded:Connect(function(Player)
    GameAnalytics:PlayerJoined(Player)
end)

-- Players leaving
Players.PlayerRemoving:Connect(function(Player)
    GameAnalytics:PlayerRemoved(Player)
end)
