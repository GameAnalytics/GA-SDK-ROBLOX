--[[
	Postie 1.1.0 by BenSBk
	Depends on:
	- The Roblox API
	- A RemoteEvent named Sent
	- A RemoteEvent named Received

	Postie is a safe alternative to RemoteFunctions with a time-out.

	Postie.invokeClient( // yields, server-side
		player: Player,
		id: string,
		timeOut: number,
		...data: any
	) => didRespond: boolean, ...response: any

		Invoke player with sent data. Invocation identified by id. Yield until
		timeOut (given in seconds) is reached and return false, or a response is
		received back from the client and return true plus the data returned
		from the client. If the invocation reaches the client, but the client
		doesn't have a corresponding callback, return before timeOut regardless
		but return false.

	Postie.invokeServer( // yields, client-side
		id: string,
		timeOut: number,
		...data: any
	) => didRespond: boolean, ...response: any

		Invoke the server with sent data. Invocation identified by id. Yield
		until timeOut (given in seconds) is reached and return false, or a
		response is received back from the server and return true plus the data
		returned from the server. If the invocation reaches the server, but the
		server doesn't have a corresponding callback, return before timeOut
		regardless but return false.

	Postie.setCallback(
		id: string,
		callback?: (...data: any) -> ...response: any
	)

		Set the callback that is invoked when an invocation identified by id is
		sent. Data sent with the invocation are passed to the callback. If on
		the server, the player who invoked is implicitly received as the first
		argument.

	Postie.getCallback(
		id: string
	) => callback?: (...data: any) -> ...response: any

		Return the callback corresponding with id.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

if not replicatedStorage:FindFirstChild("PostieSent") then
	--Create
	local f = Instance.new("RemoteEvent")
	f.Name = "PostieSent"
	f.Parent = replicatedStorage
end

if not replicatedStorage:FindFirstChild("PostieReceived") then
	--Create
	local f = Instance.new("RemoteEvent")
	f.Name = "PostieReceived"
	f.Parent = replicatedStorage
end

local sent = replicatedStorage.PostieSent -- RemoteEvent
local received = replicatedStorage.PostieReceived -- RemoteEvent

local isServer = RunService:IsServer()
local callbackById = {}
local listenerByUuid = {}

local Postie = {}

function Postie.invokeClient(id: string, player: Player, timeOut: number, ...: any): (boolean, ...any)
	assert(isServer, "Postie.invokeClient can only be called from the server")

	local thread = coroutine.running()
	local isResumed = false
	local uuid = HttpService:GenerateGUID(false)

	-- We await a signal from the client.
	listenerByUuid[uuid] = function(playerWhoFired, didInvokeCallback, ...)
		if playerWhoFired ~= player then
			-- The client lied about the UUID.
			return
		end
		isResumed = true
		listenerByUuid[uuid] = nil
		if didInvokeCallback then
			task.spawn(thread, true, ...)
		else
			task.spawn(thread, false)
		end
	end

	-- We await the time-out.
	task.delay(timeOut, function()
		if isResumed then
			return
		end
		listenerByUuid[uuid] = nil
		task.spawn(thread, false)
	end)

	-- Finally, we send the signal to the client and await either the client's
	-- response or the time-out.
	sent:FireClient(player, id, uuid, ...)
	return coroutine.yield()
end

function Postie.invokeServer(id: string, timeOut: number, ...: any): (boolean, ...any)
	assert(not isServer, "Postie.invokeServer can only be called from the client")

	local thread = coroutine.running()
	local isResumed = false
	local uuid = HttpService:GenerateGUID(false)

	-- We await a signal from the client.
	listenerByUuid[uuid] = function(didInvokeCallback, ...)
		isResumed = true
		listenerByUuid[uuid] = nil
		if didInvokeCallback then
			task.spawn(thread, true, ...)
		else
			task.spawn(thread, false)
		end
	end

	-- We await the time-out.
	task.delay(timeOut, function()
		if isResumed then
			return
		end
		listenerByUuid[uuid] = nil
		task.spawn(thread, false)
	end)

	-- Finally, we send the signal to the client and await either the client's
	-- response or the time-out.
	sent:FireServer(id, uuid, ...)
	return coroutine.yield()
end

function Postie.setCallback(id: string, callback: ((...any) -> ...any)?)
	callbackById[id] = callback
end

function Postie.getCallback(id: string): ((...any) -> ...any)?
	return callbackById[id]
end

if isServer then
	-- We handle responses received from the client.
	received.OnServerEvent:Connect(function(player, uuid, didInvokeCallback, ...)
		local listener = listenerByUuid[uuid]
		if not listener then
			return
		end
		listener(player, didInvokeCallback, ...)
	end)

	-- We handle requests sent by the client.
	sent.OnServerEvent:Connect(function(player, id, uuid, ...)
		local callback = callbackById[id]
		if callback then
			received:FireClient(player, uuid, true, callback(player, ...))
		else
			received:FireClient(player, uuid, false)
		end
	end)
else
	-- We handle responses received from the server.
	received.OnClientEvent:Connect(function(uuid, didInvokeCallback, ...)
		local listener = listenerByUuid[uuid]
		if not listener then
			return
		end
		listener(didInvokeCallback, ...)
	end)

	-- We handle requests sent by the server.
	sent.OnClientEvent:Connect(function(id, uuid, ...)
		local callback = callbackById[id]
		if callback then
			received:FireServer(uuid, true, callback(...))
		else
			received:FireServer(uuid, false)
		end
	end)
end

return Postie
