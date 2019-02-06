--[[

    NOTE: This script should be in game.ServerScriptService

--]]

local ServerStorage = game:GetService("ServerStorage")

--Validate
if script:IsDescendantOf("ServerScriptService") then
    error("GameAnalytics: GameAnalyticsServerInitUsingSettings has to be located in game.ServerScriptService.")
    return
end

--Modules
local GameAnalytics = require(ServerStorage.GameAnalytics)
local Settings = require(ServerStorage.GameAnalytics.Settings)
local Players = game:GetService("Players")

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
if #Settings.Build > 0 then
    GameAnalytics:configureBuild(Settings.Build)
end

GameAnalytics:initialize({
    gameKey = Settings.GameKey,
    secretKey = Settings.SecretKey
})

-- Fire for players already in game
for _, Player in pairs(Players:GetPlayers()) do
    GameAnalytics:PlayerJoined(Player)
end
