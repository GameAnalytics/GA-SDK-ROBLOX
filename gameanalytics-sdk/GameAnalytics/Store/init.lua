local DS = game:GetService("DataStoreService")
local DSQ = require(script.DataStoreQueue)
local logger = require(script.Parent.Logger)
local RemoteConfigs = require(script.Parent.RemoteConfigs)

-- GetDataStore throws in an unpublished place (and when Studio API access is
-- off), so resolve it defensively: the SDK keeps working with in-memory data.
local function getPlayerDataStore()
	local success, ds = pcall(DS.GetDataStore, DS, "GA_PlayerDS_1.0.0")
	if not success then
		logger:w("DataStore unavailable, player data will not persist: " .. tostring(ds))
		return nil
	end
	return ds
end

local store = {
	PlayerDS = getPlayerDataStore(),
	AutoSaveData = 180, --Set to 0 to disable
	BasePlayerData = {
		Sessions = 0,
		Transactions = 0,
		ProgressionTries = {},
		CurrentCustomDimension01 = "",
		CurrentCustomDimension02 = "",
		CurrentCustomDimension03 = "",
		RemoteConfigs = RemoteConfigs.newRecord(),
		InitAuthorized = false,
		SdkConfig = {},
		ClientServerTimeOffset = 0,
		PlayerTeleporting = false,
		OwnedGamepasses = nil, --nil means a completely new player. {} means player with no game passes
		CountryCode = "",
		CustomUserId = "",
	},

	DataToSave = {
		"Sessions",
		"Transactions",
		"ProgressionTries",
		"CurrentCustomDimension01",
		"CurrentCustomDimension02",
		"CurrentCustomDimension03",
		"OwnedGamepasses",
	},

	--Cache
	PlayerCache = {},
	EventsQueue = {},
	DataStoreQueue = DSQ,
}

function store:GetPlayerData(Player)
	if not store.PlayerDS then
		return {}
	end

	local key = Player.UserId
	local success, PlayerData = DSQ.AddRequest(key, function()
		return store.PlayerDS:GetAsync(key) or {}
	end, 7) -- Add to a queue with 7s delay between each request

	if not success then
		logger:w("Failed to load player data for " .. tostring(key) .. ", this session will not persist")
		PlayerData = { LoadFailed = true }
	end
	return PlayerData
end

function store:GetPlayerDataFromCache(userId)
	local playerData = store.PlayerCache[tonumber(userId)]
	if playerData then
		return playerData
	end
	playerData = store.PlayerCache[tostring(userId)]
	return playerData
end

function store:GetErrorDataStore(scope)
	local ErrorDS
	local success = pcall(function()
		ErrorDS = DS:GetDataStore("GA_ErrorDS_1.0.0", scope)
	end)

	if not success then
		return nil
	end

	return ErrorDS
end

function store:SavePlayerData(Player)
	--Variables
	local PlayerData = store:GetPlayerDataFromCache(Player.UserId)
	local SavePlayerData = {}

	if not PlayerData or not store.PlayerDS or PlayerData.LoadFailed then
		return
	end

	--Fill
	for _, key in pairs(store.DataToSave) do
		SavePlayerData[key] = PlayerData[key]
	end

	--Save
	local key = Player.UserId
	DSQ.AddRequest(key, function()
		return store.PlayerDS:SetAsync(key, SavePlayerData)
	end, 7)
end

function store:IncrementErrorCount(ErrorDS, ErrorKey, step)
	if not ErrorKey or not ErrorDS then
		return nil
	end

	local success, count = DSQ.AddRequest(ErrorKey, function()
		return ErrorDS:IncrementAsync(ErrorKey, step)
	end, 7)

	if not success or type(count) ~= "number" then
		return nil
	end
	return count
end
return store
