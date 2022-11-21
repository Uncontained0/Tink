local FreeThread

local function FunctionPasser(fn, ...)
	fn(...)
end

local function Yielder()
	while true do
		FunctionPasser(coroutine.yield())
	end
end

return function(fn, ...)
	if not FreeThread then
		FreeThread = coroutine.create(Yielder)
		coroutine.resume(FreeThread)
	end

	local AquiredThread = FreeThread
	FreeThread = nil

	task.spawn(AquiredThread, fn, ...)
	FreeThread = AquiredThread
end
