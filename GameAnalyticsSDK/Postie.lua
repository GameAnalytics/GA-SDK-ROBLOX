--[[
    Postie - An elegant alternative to RemoteFunctions with a timeout
    By Dandystan

    INTERFACE:

        Function bool, Tuple Postie.InvokeClient(string id, Instance<Player> player, number timeout, Tuple args) [server_side] [yields]
         Invoke player with arguments args. Invocation identified by id. Yield until timeout (given in seconds) is reached
         and return false, or a signal is received back from the client and return true plus any values received from the
         client.

        Function bool, Tuple Postie.InvokeServer(string id, number timeout, Tuple args) [client_side] [yields]
         Invoke the server with arguments args. Invocation identified by id. Yield until timeout (given in seconds) is
         reached and return false, or a signal is received back from the server and return true plus any values received
         from the server.

        Function void Postie.SetCallback(string id, func callback)
         Set the callback that is invoked when an invocation identified by id is sent. Arguments passed with the invocation
         are passed to the callback. If on the server, the player who invoked is implicitly received as the first argument.

        Function func? Postie.GetCallback(string id)
         Return the callback associated with id.

    EXAMPLE 1 - server to client:

        Server:
            local postie = require(postieObj)

            -- arbritary func to be called whenever
            local function getTrampolinesOnScreen(player)
                -- get objects on screen from player
                local isSuccessful, trampolines = postie.InvokeClient("RequestObjectsOnScreen", player, 5, "Trampolines")
                -- check for timeout
                if isSuccessful then
                    -- validate returned data type for security purposes
                    if typeof(trampolines) == "number" then
                        return true, trampolines
                    end
                end

                return false
            end

        Client:
            local postie = require(postieObj)

            postie.SetCallback("RequestObjectsOnScreen", function(objectType)
                return objectsOnScreen[objectType]
            end)

    EXAMPLE 2 - client to server:

        Server:
            local postie = require(postieObj)

            postie.SetCallback("GetCoins", function(player)
                return playerCoins[player]
            end)

        Client:
            local postie = require(postieObj)

            local function getCoins()
                return postie.InvokeServer("GetCoins", 5)
            end
--]]

-- services:
local runService = game:GetService("RunService")

if not script:FindFirstChild("Sent") then
    --Create
    local f = Instance.new("RemoteEvent")
    f.Name = "Sent"
    f.Parent = script
end

if not script:FindFirstChild("Received") then
    --Create
    local f = Instance.new("RemoteEvent")
    f.Name = "Received"
    f.Parent = script
end

-- variables:
local sent = script.Sent
local received = script.Received
local isServer = runService:IsServer()
local idCallbacks = {}
local listeners = {}
local signalVersion = 1


-- Postie:
local postie = {}

function postie.InvokeClient(id, player, timeout, ...)
    assert(isServer, "Postie.InvokeClient can only be called from the server")
    assert(typeof(id) == "string", "bad argument #1 to Postie.InvokeClient, expects string")
    assert(typeof(player) == "Instance" and player:IsA("Player"), "bad argument #2 to Postie.InvokeClient, expects Instance<Player>")
    assert(typeof(timeout) == "number", "bad argument #3 to Postie.InvokeClient, expects number")

    -- define variables
    local thread = coroutine.running()
    local isResumed = false
    local pos = #listeners + 1
    -- get signal version
    local version = signalVersion
    signalVersion = signalVersion + 1
    -- await signal from client
    listeners[pos] = function(playerWhoFired, versionOfSignal, ...)
        if not (playerWhoFired == player and versionOfSignal == version) then return end
        isResumed = true
        table.remove(listeners, pos)
        coroutine.resume(thread, true, ...)

        return true
    end
    -- await timeout
    coroutine.wrap(function()
        wait(timeout)
        if isResumed then return end
        table.remove(listeners, pos)
        coroutine.resume(thread, false)
    end)()
    -- send signal
    sent:FireClient(player, id, version, ...)

    return coroutine.yield()
end

function postie.InvokeServer(id, timeout, ...)
    assert(not isServer, "Postie.InvokeServer can only be called from the client")
    assert(typeof(id) == "string", "bad argument #1 to Postie.InvokeServer, expects string")
    assert(typeof(timeout) == "number", "bad argument #2 to Postie.InvokeServer, expects number")

    -- define variables
    local thread = coroutine.running()
    local isResumed = false
    local pos = #listeners + 1
    -- get signal version
    local version = signalVersion
    signalVersion = signalVersion + 1
    -- await signal from client
    listeners[pos] = function(versionOfSignal, ...)
        if versionOfSignal ~= id then return end
        isResumed = true
        table.remove(listeners, pos)
        coroutine.resume(thread, true, ...)

        return true
    end
    -- await timeout
    coroutine.wrap(function()
        wait(timeout)
        if isResumed then return end
        table.remove(listeners, pos)
        coroutine.resume(thread, false)
    end)()
    -- send signal
    sent:FireServer(id, version, ...)

    return coroutine.yield()
end

function postie.SetCallback(id, callback)
    assert(typeof(id) == "string", "bad argument #1 to Postie.SetCallback, expects string")
    assert(typeof(callback) == "function", "bad argument #2 to Postie.SetCallback, expects func")

    idCallbacks[id] = callback
end

function postie.GetCallback(id)
    assert(typeof(id) == "string", "bad argument #1 to Postie.GetCallback, expects string")

    return idCallbacks[id]
end


-- main:
-- handle signals
if isServer then
    -- handle received
    received.OnServerEvent:Connect(function(...)
        for _, listener in ipairs(listeners) do
            if listener(...) then return end
        end
    end)
    -- handle sent
    sent.OnServerEvent:Connect(function(player, id, version, ...)
        local callback = idCallbacks[id]
        received:FireClient(player, version, callback and callback(player, ...))
    end)
else
    -- handle received
    received.OnClientEvent:Connect(function(...)
        for _, listener in ipairs(listeners) do
            if listener(...) then return end
        end
    end)
    -- handle sent
    sent.OnClientEvent:Connect(function(id, version, ...)
        local callback = idCallbacks[id]
        received:FireServer(version, callback and callback(...))
    end)
end

return postie
