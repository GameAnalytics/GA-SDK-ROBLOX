local DS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local store = {
	PlayerDS = RunService:IsStudio() and {} or DS:GetDataStore("GA_PlayerDS_1.0.0"),
	AutoSaveData = 180, --Set to 0 to disable
	BasePlayerData = {
		Sessions = 0,
		Transactions = 0,
		ProgressionTries = {},
		CurrentCustomDimension01 = "",
		CurrentCustomDimension02 = "",
		CurrentCustomDimension03 = "",
		ConfigsHash = "",
		AbId = "",
		AbVariantId = "",
		InitAuthorized = false,
		SdkConfig = {},
		ClientServerTimeOffset = 0,
		Configurations = {},
		RemoteConfigsIsReady = false,
		PlayerTeleporting = false,
		OwnedGamepasses = nil, --nil means a completely new player. {} means player with no game passes
		CountryCode = "",
		CustomUserId = ""
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
}

function store:GetPlayerData(Player)
	local PlayerData
	local success = pcall(function()
		PlayerData = RunService:IsStudio() and {} or (store.PlayerDS:GetAsync(Player.UserId) or {})
	end)

	if not success then
		PlayerData = {}
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
		ErrorDS = RunService:IsStudio() and {} or DS:GetDataStore("GA_ErrorDS_1.0.0", scope)
	end)

	if not success then
		ErrorDS = {}
	end

	return ErrorDS
end

function store:SavePlayerData(Player)

	--Variables
	local PlayerData = store:GetPlayerDataFromCache(Player.UserId)
	local SavePlayerData = {}

	if not PlayerData then
		return
	end

	--Fill
	for _, key in pairs(store.DataToSave) do
		SavePlayerData[key] = PlayerData[key]
	end

	--Save
	if not RunService:IsStudio() then
		pcall(function()
			store.PlayerDS:SetAsync(Player.UserId, SavePlayerData)
		end)
	end
end

function store:IncrementErrorCount(ErrorDS, ErrorKey, step)
	if not ErrorKey then
		return
	end

	local count = 0
	--Increment count
	if not RunService:IsStudio() then
		pcall(function()
			count = ErrorDS:IncrementAsync(ErrorKey, step)
		end)
	end

	return count
end

return store
