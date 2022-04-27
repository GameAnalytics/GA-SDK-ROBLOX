local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameAnalytics = require(ReplicatedStorage.GameAnalyticsSDK)
local GameAnalyticsInit = require(ReplicatedStorage.GameAnalyticsSDK.Initialize)

GameAnalyticsInit.initServer("", "")
