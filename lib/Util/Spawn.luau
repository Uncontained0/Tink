local FreeThread: thread? = nil

local function FunctionPasser(fn, ...)
	fn(...)
end

local function Yielder()
	while true do
		FunctionPasser(coroutine.yield())
	end
end

return function<T...>(fn: (T...) -> () | thread, ...: T...)
	if not FreeThread then
		FreeThread = coroutine.create(Yielder)
		coroutine.resume(FreeThread :: any)
	end

	local AquiredThread = FreeThread
	FreeThread = nil

	task.spawn(AquiredThread :: any, fn, ...)
	FreeThread = AquiredThread
end
