local threading = {
    _canSafelyClose = true,
    _endThread = false,
    _isRunning = false,
    _nextSeqNum = 0,
    _blocks = {}
}

local logger = require(script.Parent.Logger)
local RunService = game:GetService("RunService")

local function getNextBlock()
    local now = tick()
    if #threading._blocks ~= 0 and threading._blocks[1].deadline <= now then
        return table.remove(threading._blocks, 1)
    else
        return nil
    end
end

local function compare(a, b)
    if a.deadline == b.deadline then
        return a.seqNum < b.seqNum
    else
        return a.deadline < b.deadline
    end
end

local function run()

    spawn(function()
        logger:d("Starting GA thread")

        while not threading._endThread do
            threading._canSafelyClose = false
            local timedBlock = getNextBlock()
            while timedBlock ~= nil do
                timedBlock.block()
                timedBlock = getNextBlock()
            end

            threading._canSafelyClose = true

            wait(1)
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
        wait(1)

        --Delay
        if not threading._canSafelyClose then
            repeat
                wait()
            until threading._canSafelyClose
        end
        wait(3)
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
        seqNum = self._nextSeqNum
    }
    self._nextSeqNum = self._nextSeqNum + 1

    if #self._blocks > 0 then
        for i = #self._blocks, 1, -1
        do
            if not compare(timedBlock, self._blocks[i]) then
                table.insert(self._blocks, i + 1, timedBlock)
                break
            end

            if i == 1 then
                table.insert(self._blocks, i, timedBlock)
            end
        end
    else
        self._blocks[#self._blocks + 1] = timedBlock
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
        deadline = tick(),
        seqNum = self._nextSeqNum
    }
    self._nextSeqNum = self._nextSeqNum + 1

    if #self._blocks > 0 then
        for i = #self._blocks, 1, -1
        do
            if not compare(timedBlock, self._blocks[i]) then
                table.insert(self._blocks, i + 1, timedBlock)
                break
            end

            if i == 1 then
                table.insert(self._blocks, i, timedBlock)
            end
        end
    else
        self._blocks[#self._blocks + 1] = timedBlock
    end
end

function threading:stopThread()
    self._endThread = true
end

return threading
