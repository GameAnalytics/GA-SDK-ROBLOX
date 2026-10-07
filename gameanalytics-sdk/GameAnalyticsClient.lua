local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

local RemoteConfigs = require(script.Parent.GameAnalytics.RemoteConfigs)
local types = require(script.Parent.GameAnalytics.Types)

type RemoteConfigsOptions = types.RemoteConfigsOptions

local REMOTE_CONFIGS_EVENT_TIMEOUT = 10

local remoteConfigsUpdated = Instance.new("BindableEvent")
local remoteConfigValues = {}
local remoteConfigTypes = {}
local remoteConfigsReady = false

local module = {
	OnRemoteConfigsUpdated = remoteConfigsUpdated.Event,
}

local function applyRemoteConfigs(values, configTypes)
	remoteConfigValues = values or {}
	remoteConfigTypes = configTypes or {}
	remoteConfigsReady = true
	remoteConfigsUpdated:Fire()
end

local function getPlatform()
	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "Mobile"
	else
		return "Desktop"
	end
end

local function reportError(message, stackTrace, scriptInst)
	if not scriptInst then
		return
	end

	local ok, scriptName = pcall(scriptInst.GetFullName, scriptInst)
	if not ok then
		return
	end

	ReplicatedStorage.GameAnalyticsError:FireServer(message, stackTrace, scriptName)
end

function module.initClient()
	local Postie = require(script.Parent.GameAnalytics.Postie)

	ScriptContext.Error:Connect(reportError)
	Postie.setCallback("getPlatform", getPlatform)

	task.spawn(function()
		local remote = ReplicatedStorage:WaitForChild("GameAnalyticsRemoteConfigs", REMOTE_CONFIGS_EVENT_TIMEOUT)
		if not remote then
			warn("GameAnalytics: remote configs event not found, is the server SDK initialized?")
			return
		end
		remote.OnClientEvent:Connect(applyRemoteConfigs)
	end)
end

function module:getRemoteConfigsValueAsString(options: RemoteConfigsOptions)
	return RemoteConfigs.getValueAsString(remoteConfigValues, options.key or "", options.defaultValue)
end

function module:getRemoteConfigsValueAsJson(options: RemoteConfigsOptions)
	return RemoteConfigs.getValueAsJson(remoteConfigValues, remoteConfigTypes, options.key or "", options.defaultValue)
end

function module:getRemoteConfigsContentAsString()
	return RemoteConfigs.getContentAsString(remoteConfigValues)
end

function module:isRemoteConfigsReady()
	return remoteConfigsReady
end

return module
