local RunService = game:GetService("RunService")
--local GameAnalyticsSendMessage

local logger = {
	_infoLogEnabled = false,
	_infoLogAdvancedEnabled = false,
	_debugEnabled = RunService:IsStudio(),
}

function logger:setDebugLog(enabled)
	self._debugEnabled = enabled
end

function logger:setInfoLog(enabled)
	self._infoLogEnabled = enabled
end

function logger:setVerboseLog(enabled)
	self._infoLogAdvancedEnabled = enabled
end

function logger:i(format)
	if not self._infoLogEnabled then
		return
	end

	local m = "Info/GameAnalytics: " .. format
	print(m)
--    GameAnalyticsSendMessage = GameAnalyticsSendMessage or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsSendMessage")
--    GameAnalyticsSendMessage:FireAllClients({
--        Text = m,
--        Font = Enum.Font.Arial,
--        Color = Color3.new(255, 255, 255),
--        FontSize = Enum.FontSize.Size96
--    })
end

function logger:w(format)
	local m = "Warning/GameAnalytics: " .. format
	warn(m)
--    GameAnalyticsSendMessage = GameAnalyticsSendMessage or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsSendMessage")
--    GameAnalyticsSendMessage:FireAllClients({
--        Text = m,
--        Font = Enum.Font.Arial,
--        Color = Color3.new(255, 255, 0),
--        FontSize = Enum.FontSize.Size96
--    })
end

function logger:e(format)
	task.spawn(function()
		local m = "Error/GameAnalytics: " .. format
		error(m, 0)
--        GameAnalyticsSendMessage = GameAnalyticsSendMessage or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsSendMessage")
--        GameAnalyticsSendMessage:FireAllClients({
--            Text = m,
--            Font = Enum.Font.Arial,
--            Color = Color3.new(255, 0, 0),
--            FontSize = Enum.FontSize.Size96
--        })
	end)
end

function logger:d(format)
	if not self._debugEnabled then
		return
	end

	local m = "Debug/GameAnalytics: " .. format
	print(m)
--    GameAnalyticsSendMessage = GameAnalyticsSendMessage or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsSendMessage")
--    GameAnalyticsSendMessage:FireAllClients({
--        Text = m,
--        Font = Enum.Font.Arial,
--        Color = Color3.new(255, 255, 255),
--        FontSize = Enum.FontSize.Size96
--    })
end

function logger:ii(format)
	if not self._infoLogAdvancedEnabled then
		return
	end

	local m = "Verbose/GameAnalytics: " .. format
	print(m)
--    GameAnalyticsSendMessage = GameAnalyticsSendMessage or game:GetService("ReplicatedStorage"):WaitForChild("GameAnalyticsSendMessage")
--    GameAnalyticsSendMessage:FireAllClients({
--        Text = m,
--        Font = Enum.Font.Arial,
--        Color = Color3.new(255, 255, 255),
--        FontSize = Enum.FontSize.Size96
--    })
end

return logger
