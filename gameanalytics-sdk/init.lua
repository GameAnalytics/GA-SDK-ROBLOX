local RunService = game:GetService("RunService")

--[[
	This script determines if we should load gameanalytics server or client.
]]

local isServer = RunService:IsServer()


if isServer then
	return require(script.GameAnalytics)
else
	return require(script.GameAnalyticsClient)
end
