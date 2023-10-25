local module = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

--[[
    The modules are required inside each function because we wouldn't
    want to load the GameAnalytics library if we're just requiring this
    ModuleScript on the client side, and we don't need to hard code
    a require to Postie on the server side because the networking implementation could change.
]]

function module.initClient()
	local Postie = require(script.Parent.GameAnalytics.Postie)

	ScriptContext.Error:Connect(function(message, stackTrace, scriptInst)
		if not scriptInst then
			return
		end

		local scriptName = nil
		local ok, _ = pcall(function()
			scriptName = scriptInst:GetFullName() -- Can't get name of some scripts because of security permission
		end)
		if not ok then
			return
		end

		ReplicatedStorage.GameAnalyticsError:FireServer(message, stackTrace, scriptName)
	end)

	--Functions
	local function getPlatform()
		if GuiService:IsTenFootInterface() then
			return "Console"
		elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			return "Mobile"
		else
			return "Desktop"
		end
	end

	--Filtering
	Postie.setCallback("getPlatform", getPlatform)
end

return module
