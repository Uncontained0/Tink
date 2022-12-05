local Promise = require(script.Parent.Promise)
local Spawn = require(script.Parent.Spawn)

local Connection = {}
Connection.__index = Connection

function Connection.new(Signal: { _Root: Connection? }, Callback: (...any) -> ()): Connection
	local self = setmetatable({}, Connection)

	self._Signal = Signal
	self._Callback = Callback
	self._Next = nil :: Connection?

	return self
end

function Connection:Disconnect()
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

export type Connection = typeof(Connection.new({ _Root = nil :: Connection? }, function() end))

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)

	self._Root = nil :: Connection?

	return self
end

function Signal:Connect(Callback): Connection
	local Connection = Connection.new(self, Callback)

	Connection._Next = self._Root
	self._Root = Connection

	return Connection
end

function Signal:Fire(...)
	local Current = self._Root

	while Current do
		Spawn(Current._Callback, ...)

		Current = Current._Next
	end
end

function Signal:Wait(): Promise.Promise
	return Promise.new(function(Resolve)
		local Connection
		Connection = self:Connect(function(...)
			Connection:Disconnect()
			Resolve(...)
		end)
	end)
end

export type Signal = typeof(Signal.new())

return Signal
