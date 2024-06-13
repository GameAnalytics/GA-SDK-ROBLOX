local DataStoreManager = {}
DataStoreManager.QR = true
DataStoreManager.Queue = {}
DataStoreManager.Process = 0
local LastRequest = {}

task.spawn(function()
	while DataStoreManager.QR do
		task.wait()
		if #DataStoreManager.Queue > 0 then
			local Request = DataStoreManager.Queue[1]
			table.remove(DataStoreManager.Queue, 1)
			if not LastRequest[Request.Key] then
				LastRequest[Request.Key] = 0
			end

			DataStoreManager.Process += 1
			local remain = (Request.Delay + LastRequest[Request.Key]) - DateTime.now().UnixTimestamp
			if remain <= 0 then
				remain = 0
			end
			task.delay(remain, function()
				local Success, Error, ds
				repeat
					LastRequest[Request.Key] = DateTime.now().UnixTimestamp
					Success, Error, ds = pcall(Request.Func)

					if not Success then
						warn(Error)
					end
					if Success and Error then
						break
					end
					if not Request.Delay then
						break
					end
					task.wait(Request.Delay)
				until Success and Error
				Request.Event:Fire(Success, Error, ds)
				DataStoreManager.Process -= 1
				LastRequest[Request.Key] = DateTime.now().UnixTimestamp
			end)
		end
	end
end)

function DataStoreManager.AddRequest(Key, Request, Delay)
	local FinishedEvent = Instance.new("BindableEvent")
	table.insert(DataStoreManager.Queue, {
		Key = Key,
		Delay = Delay,
		Func = Request,
		Event = FinishedEvent,
	})
	local Success, ValOrErr, ds = FinishedEvent.Event:Wait()
	return Success, ValOrErr, ds
end

function DataStoreManager.RemoveKey(Key)
	LastRequest[Key] = nil
end
return DataStoreManager
