local Promise = require(script.Parent.Promise)
local Spawn = require(script.Parent.Spawn)

local SignalConnection = {}
SignalConnection.__index = SignalConnection

function SignalConnection.new(Signal, Callback)
	local self = setmetatable({}, SignalConnection)
	
	SignalConnection.constructor(self, Signal, Callback)

	return self
end

function SignalConnection:constructor(Signal, Callback)
	self._Signal = Signal
	self._Callback = Callback
end

function SignalConnection:DisConnect()
	if self._Signal._Root == self then
		self._Signal._Root = self._Next
	else
		local Current = self._Signal._Root

		while Current do
			if Current._Next == self then
				Current._Next = self._Next
				break
			end

			Current = Current._Next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({}, Signal)
end

function Signal:Connect(Callback)
	local Connection = SignalConnection.new(self, Callback)

	if self._Root then
		Connection._Next = self._Root
	end

	self._Root = Connection

	return Connection
end

function Signal:Wait()
	return Promise.new(function(resolve)
		local Connection

		Connection = self:Connect(function(...)
			Connection:DisConnect()
			resolve(...)
		end)
	end)
end

function Signal:Fire(...)
	local Current = self._Root

	while Current do
		Spawn(Current._Callback, ...)
		Current = Current._Next
	end
end

return Signal