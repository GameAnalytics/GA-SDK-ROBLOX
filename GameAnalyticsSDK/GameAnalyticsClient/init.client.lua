--Variables
--local GameAnalyticsSendMessage = game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsSendMessage")

--Services
local GS = game:GetService("GuiService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Postie = require(script.Postie)
local ScriptContext = game:GetService("ScriptContext")

ScriptContext.Error:Connect(function(message, stackTrace, scriptInst)
	if not scriptInst then
		return
	end

	local scriptName = nil
	local ok, _ = pcall(function()
		scriptName = scriptInst:GetFullName()  -- Can't get name of some scripts because of security permission
	end)
	if not ok then
		return
	end

	ReplicatedStorage.GameAnalyticsError:FireServer(message, stackTrace, scriptName)
end)

--Functions
local function getPlatform()

	if GS:IsTenFootInterface() then
		return "Console"
	elseif UIS.TouchEnabled and not UIS.MouseEnabled then
		return "Mobile"
	else
		return "Desktop"
	end
end

--Filtering
Postie.setCallback("getPlatform", getPlatform)
