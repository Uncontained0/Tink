local FreeThread: thread? = nil

local function FunctionPasser(fn, ...)
	local AquiredThread = FreeThread
	FreeThread = nil
	fn(...)
	FreeThread = AquiredThread
end

local function Yielder()
	while true do
		FunctionPasser(coroutine.yield())
	end
end

return function(fn: (...any) -> () | thread, ...)
	if not FreeThread then
		FreeThread = coroutine.create(Yielder)
		coroutine.resume(FreeThread)
	end

	task.spawn(FreeThread, fn, ...)
end
