--[[

    NOTE: This script should be in game.ServerScriptService

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--Validate
if script.Parent.ClassName ~= "ServerScriptService" then
    warn("GameAnalytics: Disabled server")
    return
end

--Filtering
if not ReplicatedStorage:FindFirstChild("GameAnalyticsFiltering") then
    --Create
    local f = Instance.new("RemoteFunction")
    f.Name = "GameAnalyticsFiltering"
    f.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("GameAnalyticsSendMessage") then
    --Create
    local f = Instance.new("RemoteEvent")
    f.Name = "GameAnalyticsSendMessage"
    f.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("GameAnalyticsCommandCenter") then
    --Create
    local f = Instance.new("RemoteEvent")
    f.Name = "GameAnalyticsCommandCenter"
    f.Parent = ReplicatedStorage
end

--Modules
local GameAnalytics = require(ServerStorage.GameAnalytics)
local Settings = require(ServerStorage.GameAnalytics.Settings)
local store = require(ServerStorage.GameAnalytics.Store)
local LS = game:GetService("LogService")
local MKT = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProductCache = {}

--Error Logging
LS.MessageOut:Connect(function(message, messageType)

    --Validate
    if not Settings.ReportErrors then return end
    if messageType ~= Enum.MessageType.MessageError then return end

    local m = message
    if string.len(m) > 8192 then
        m = string.sub(m, 1, 8192)
    end

    local key = m
    if string.len(key) > 50 then
        m = string.sub(key, 1, 50)
    end

    local ErrorData = store:GetErrorData(key)
    local now = os.time()
    local hour_in_seconds = 3600

    if not ErrorData then
        ErrorData = {}
    end

    if not ErrorData.timestamp then
        ErrorData.timestamp = os.time()
    end

    if not ErrorData.count then
        ErrorData.count = 0
    end

    -- reset count after one hour
    if now - ErrorData.timestamp > hour_in_seconds then
        ErrorData.count = 0
        ErrorData.timestamp = os.time()
    end

    -- don't report error if limit has been exceeded
    if ErrorData.count and ErrorData.count > Settings.MaxErrorsPerHour then
        return
    end

    --Report
    GameAnalytics:addErrorEvent(GameAnalytics.EGAErrorSeverity.Error, m)

    -- increment error count
    ErrorData.count = ErrorData.count + 1

    -- save error count and timestamp
    store:SaveErrorData(key, ErrorData)
end)

if Settings.EnableInfoLog then
    GameAnalytics:setEnabledInfoLog(Settings.EnableInfoLog)
end
if Settings.EnableVerboseLog then
    GameAnalytics:setEnabledVerboseLog(Settings.EnableVerboseLog)
end

if #Settings.AvailableCustomDimensions01 > 0 then
    GameAnalytics:configureAvailableCustomDimensions01(Settings.AvailableCustomDimensions01)
end
if #Settings.AvailableCustomDimensions02 > 0 then
    GameAnalytics:configureAvailableCustomDimensions02(Settings.AvailableCustomDimensions02)
end
if #Settings.AvailableCustomDimensions03 > 0 then
    GameAnalytics:configureAvailableCustomDimensions03(Settings.AvailableCustomDimensions03)
end
if #Settings.AvailableResourceCurrencies > 0 then
    GameAnalytics:configureAvailableResourceCurrencies(Settings.AvailableResourceCurrencies)
end
if #Settings.AvailableResourceItemTypes > 0 then
    GameAnalytics:configureAvailableResourceItemTypes(Settings.AvailableResourceItemTypes)
end
if string.len(Settings.Build) > 0 then
    GameAnalytics:configureBuild(Settings.Build)
end

if Settings.AutomaticSendBusinessEvents then
    --Record Gamepasses. NOTE: This doesn't record gamepass purchases if a player buys it from the website
    MKT.PromptGamePassPurchaseFinished:Connect(function(Player, ID, Purchased)

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
end

GameAnalytics:initialize({
    gameKey = Settings.GameKey,
    secretKey = Settings.SecretKey
})

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
