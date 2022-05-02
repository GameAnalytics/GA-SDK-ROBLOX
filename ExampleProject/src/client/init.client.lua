local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- using wally package
--local GameAnalytics = require(ReplicatedStorage.Packages.GameAnalytics)
-- using rojo or manually copied in
local GameAnalytics = require(ReplicatedStorage.GameAnalytics)

GameAnalytics:initClient()
