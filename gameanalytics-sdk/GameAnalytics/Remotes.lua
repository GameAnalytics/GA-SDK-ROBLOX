local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Postie = require(script.Parent.Postie)

local CLIENT_TIMEOUT = 5

local function ensureInstance(className, name)
	local instance = ReplicatedStorage:FindFirstChild(name)
	if not instance then
		instance = Instance.new(className)
		instance.Name = name
		instance.Parent = ReplicatedStorage
	end
	return instance
end

local remoteConfigsUpdated = Instance.new("BindableEvent")

local Remotes = {
	RemoteConfigs = ensureInstance("RemoteEvent", "GameAnalyticsRemoteConfigs"),
	Error = ensureInstance("RemoteEvent", "GameAnalyticsError"),
	PlayerReady = ensureInstance("BindableEvent", "OnPlayerReadyEvent"),
	OnRemoteConfigsUpdated = remoteConfigsUpdated.Event,
}

function Remotes.fireRemoteConfigs(player, values, types)
	Remotes.RemoteConfigs:FireClient(player, values, types)
end

function Remotes.fireRemoteConfigsUpdated(player)
	remoteConfigsUpdated:Fire(player)
end

function Remotes.firePlayerReady(player)
	Remotes.PlayerReady:Fire(player)
end

function Remotes.requestPlatform(player)
	return Postie.invokeClient("getPlatform", player, CLIENT_TIMEOUT)
end

function Remotes.requestCustomUserId(player)
	return Postie.invokeClient("getCustomUserId", player, CLIENT_TIMEOUT)
end

function Remotes.onClientError(handler)
	return Remotes.Error.OnServerEvent:Connect(handler)
end

return Remotes
