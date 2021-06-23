--[[
	Postie: An elegant alternative to RemoteFunctions with a timeout
	https://devforum.roblox.com/t/postie-an-elegant-alternative-to-remotefunctions-with-a-timeout/243812
	By Dandystan

	INTERFACE:

		Function Postie.InvokeClient(id: string, player: Instance<Player>, timeout: number, ...args: any) -> boolean, ...any // yields, server-side
		 Invoke player with arguments args. Invocation identified by id. Yield until timeout (given in seconds) is reached
		 and return false, or a signal is received back from the client and return true plus any values received from the
		 client.

		Function Postie.InvokeServer(id: string, timeout: number, ...args: any) -> boolean, ...any // yields, client-side
		 Invoke the server with arguments args. Invocation identified by id. Yield until timeout (given in seconds) is
		 reached and return false, or a signal is received back from the server and return true plus any values received
		 from the server.

		Function Postie.SetCallback(id: string, callback?: (...args: any))
		 Set the callback that is invoked when an invocation identified by id is sent. Arguments passed with the invocation
		 are passed to the callback. If on the server, the player who invoked is implicitly received as the first argument.

		Function Postie.GetCallback(id: string) -> (...)?
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

-- dependencies:
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

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

-- data:
local sent = script.Sent
local received = script.Received
local isServer = runService:IsServer()
local idToCallbackMap = {}
local listeners = {}

-- functions:
-- SpawnNow(callback: (...args: any), ...args: any)
local function spawnNow(callback, ...)
	local bindable = Instance.new("BindableEvent")
	local arguments = table.pack(...)
	bindable.Event:Connect(function()
		callback(table.unpack(arguments, 1, arguments.n))
	end)
	bindable:Fire()
	bindable:Destroy()
end


-- Postie:
local postie = {}

-- Function Postie.InvokeClient(id: string, player: Instance<Player>, timeout: number, ...args: any) -> boolean, ...any // yields, server-side
function postie.InvokeClient(id, player, timeout, ...)
	assert(isServer, "Postie.InvokeClient can only be called from the server")
	assert(typeof(id) == "string", "bad argument #1 to Postie.InvokeClient, expects string")
	assert(typeof(player) == "Instance" and player:IsA("Player"), "bad argument #2 to Postie.InvokeClient, expects Instance<Player>")
	assert(typeof(timeout) == "number", "bad argument #3 to Postie.InvokeClient, expects number")
	local bindable = Instance.new("BindableEvent")
	local isResumed = false
	local pos = #listeners + 1
	-- get uuid
	local uuid = httpService:GenerateGUID(false)
	-- await signal from client
	listeners[pos] = function(playerWhoFired, signalUuid, ...)
		if not (playerWhoFired == player and signalUuid == uuid) then return false end
		isResumed = true
		table.remove(listeners, pos)
		bindable:Fire(true, ...)
		return true
	end
	-- await timeout
	spawnNow(function()
		wait(timeout)
		if isResumed then return end
		table.remove(listeners, pos)
		bindable:Fire(false)
	end)
	-- send signal
	sent:FireClient(player, id, uuid, ...)
	return bindable.Event:Wait()
end

-- Function Postie.InvokeServer(id: string, timeout: number, ...args: any) -> boolean, ...any // yields, client-side
function postie.InvokeServer(id, timeout, ...)
	assert(not isServer, "Postie.InvokeServer can only be called from the client")
	assert(typeof(id) == "string", "bad argument #1 to Postie.InvokeServer, expects string")
	assert(typeof(timeout) == "number", "bad argument #2 to Postie.InvokeServer, expects number")
	local bindable = Instance.new("BindableEvent")
	local isResumed = false
	local pos = #listeners + 1
	-- get uuid
	local uuid = httpService:GenerateGUID(false)
	-- await signal from client
	listeners[pos] = function(signalUuid, ...)
		if signalUuid ~= uuid then return false end
		isResumed = true
		table.remove(listeners, pos)
		bindable:Fire(true, ...)
		return true
	end
	-- await timeout
	spawnNow(function()
		wait(timeout)
		if isResumed then return end
		table.remove(listeners, pos)
		bindable:Fire(false)
	end)
	-- send signal
	sent:FireServer(id, uuid, ...)
	return bindable.Event:Wait()
end

-- Function Postie.SetCallback(id: string, callback?: (...args: any))
function postie.SetCallback(id, callback)
	assert(typeof(id) == "string", "bad argument #1 to Postie.SetCallback, expects string")
	idToCallbackMap[id] = callback
end

-- Function Postie.GetCallback(id: string) -> (...)?
function postie.GetCallback(id)
	assert(typeof(id) == "string", "bad argument #1 to Postie.GetCallback, expects string")
	return idToCallbackMap[id]
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
	sent.OnServerEvent:Connect(function(player, id, uuid, ...)
		local callback = idToCallbackMap[id]
		received:FireClient(player, uuid, callback and callback(player, ...))
	end)
else
	-- handle received
	received.OnClientEvent:Connect(function(...)
		for _, listener in ipairs(listeners) do
			if listener(...) then return end
		end
	end)
	-- handle sent
	sent.OnClientEvent:Connect(function(id, uuid, ...)
		local callback = idToCallbackMap[id]
		received:FireServer(uuid, callback and callback(...))
	end)
end

return postie
