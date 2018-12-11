local DS = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local store = {
	PlayerDS = RunService:IsStudio() and {} or DS:GetDataStore("GA_PlayerDS_1.0.0"),
    ErrorDS = RunService:IsStudio() and {} or DS:GetDataStore("GA_ErrorDS_1.0.0"),
	AutoSaveData = 180, --Set to 0 to disable
    BasePlayerData = {
        Sessions = 0,
        Transactions = 0,
		ProgressionTries = {},
		CurrentCustomDimension01 = "",
		CurrentCustomDimension02 = "",
		CurrentCustomDimension03 = "",
		InitAuthorized = false,
		SdkConfig = {},
		ClientServerTimeOffset = 0,
		Configurations = {},
		CommandCenterIsReady = false
    },
    DataToSave = {
		"Sessions", 
		"Transactions", 
		"ProgressionTries",
		"CurrentCustomDimension01",
		"CurrentCustomDimension02",
		"CurrentCustomDimension03"
	},

    --Cache
    PlayerCache = {},
	EventsQueue = {}
}

function store:GetPlayerData(Player)
	local PlayerData
	local success, err = pcall(function()
		PlayerData = RunService:IsStudio() and {} or (store.PlayerDS:GetAsync(Player.UserId) or {})
	end)
	
	if not success then
		PlayerData = {}
	end
	
	return PlayerData
end

function store:GetErrorData(Error)
	local ErrorData
	local success, err = pcall(function()
		ErrorData = RunService:IsStudio() and {} or (store.ErrorDS:GetAsync(Error) or {})
	end)
	
	if not success then
		ErrorData = {}
	end
	
	return ErrorData
end

function store:SavePlayerData(Player)

    --Variables
    local PlayerData = store.PlayerCache[Player.UserId]
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
		local success, err = pcall(function()
			store.PlayerDS:SetAsync(Player.UserId, SavePlayerData)
		end)
	end
end

function store:SaveErrorData(ErrorKey, ErrorData)
	if not ErrorData then 
		return
	end

    --Save
	if not RunService:IsStudio() then
		local success, err = pcall(function()
			store.PlayerDS:SetAsync(ErrorKey, ErrorData)
		end)
	end
end

return store
