--[[

	NOTE: This script should be in game.ServerScriptService

--]]

local ServerStorage = game:GetService("ServerStorage")
local GameAnalytics = require(ServerStorage.GameAnalytics)

GameAnalytics:initialize({
	build = "0.1",

	gameKey = "",
	secretKey = "",

	enableInfoLog = true,
	enableVerboseLog = false,

	--debug is by default enabled in studio only
	enableDebugLog = nil,

	automaticSendBusinessEvents = true,
	reportErrors = true,

	availableCustomDimensions01 = {},
	availableCustomDimensions02 = {},
	availableCustomDimensions03 = {},
	availableResourceCurrencies = {},
	availableResourceItemTypes = {},
	availableGamepasses = {}
})
