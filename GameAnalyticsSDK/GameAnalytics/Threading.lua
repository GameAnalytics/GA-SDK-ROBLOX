local threading = {
	_canSafelyClose = true,
	_endThread = false,
	_isRunning = false,
	_blocks = {},
	_scheduledBlock = nil,
	_hasScheduledBlockRun = true,
}

local logger = require(script.Parent.Logger)
local RunService = game:GetService("RunService")

local function getScheduledBlock()
	local now = tick()

	if not threading._hasScheduledBlockRun and threading._scheduledBlock ~= nil and threading._scheduledBlock.deadline <= now then
		threading._hasScheduledBlockRun = true
		return threading._scheduledBlock
	else
		return nil
	end
end

local function run()

	task.spawn(function()
		logger:d("Starting GA thread")

		while not threading._endThread do
			threading._canSafelyClose = false

			if #threading._blocks ~= 0 then
				for _, b in pairs(threading._blocks) do
					local s, e = pcall(b.block)
					if not s then
						logger:e(e)
					end
				end

				threading._blocks = {}
			end

			local timedBlock = getScheduledBlock()
			if timedBlock ~= nil then
				local s, e = pcall(timedBlock.block)
				if not s then
					logger:e(e)
				end
			end

			threading._canSafelyClose = true
			task.wait(1)
		end

		logger:d("GA thread stopped")
	end)

	--Safely Close
	game:BindToClose(function()

		-- waiting bug fix to work inside studio
		if RunService:IsStudio() then
			return
		end

		--Give game.Players.PlayerRemoving time to to its thang
		task.wait(1)

		--Delay
		if not threading._canSafelyClose then
			repeat
				task.wait()
			until threading._canSafelyClose
		end

		task.wait(3)
	end)
end

function threading:scheduleTimer(interval, callback)
	if self._endThread then
		return
	end

	if not self._isRunning then
		self._isRunning = true
		run()
	end

	local timedBlock = {
		block = callback,
		deadline = tick() + interval,
	}

	if self._hasScheduledBlockRun then
		self._scheduledBlock = timedBlock
		self._hasScheduledBlockRun = false
	end
end

function threading:performTaskOnGAThread(callback)
	if self._endThread then
		return
	end

	if not self._isRunning then
		self._isRunning = true
		run()
	end

	local timedBlock = {
		block = callback,
	}

	self._blocks[#self._blocks + 1] = timedBlock
end

function threading:stopThread()
	self._endThread = true
end

return threading
