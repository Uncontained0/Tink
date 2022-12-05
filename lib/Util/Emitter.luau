local Promise = require(script.Parent.Promise)
local Spawn = require(script.Parent.Spawn)

local Connection = {}
Connection.__index = Connection

function Connection.new(
	Emitter: { _Root: { [string]: Connection } },
	Event: string,
	Callback: (...any) -> ()
): Connection
	local self = setmetatable({}, Connection)

	self._Emitter = Emitter
	self._Event = Event
	self._Callback = Callback
	self._Next = nil :: Connection?

	return self
end

function Connection:Disconnect()
	if self._Emitter._Root[self._Event] == self then
		self._Emitter._Root[self._Event] = self._Next
	else
		local Current = self._Emitter._Root[self._Event]

		while Current do
			if Current._Next == self then
				Current._Next = self._Next
				break
			end

			Current = Current._Next
		end
	end
end

export type Connection = typeof(Connection.new({ _Root = {} }, "", function() end))

local Emitter = {}
Emitter.__index = Emitter

function Emitter.new()
	local self = setmetatable({}, Emitter)

	self._Root = {} :: { [string]: Connection }

	return self
end

function Emitter:Connect(Event: string, Callback: (...any) -> ()): Connection
	local Connection = Connection.new(self, Event, Callback)

	Connection._Next = self._Root[Event]
	self._Root[Event] = Connection

	return Connection
end

Emitter.On = Emitter.Connect

function Emitter:Fire(Event: string, ...)
	local Current = self._Root[Event]

	if Current == nil then
		warn("Attempted to fire event " .. Event .. " on an emitter with no connections.")
	end

	while Current do
		Spawn(Current._Callback, ...)
		Current = Current._Next
	end
end

function Emitter:Wait(Event: string): Promise.Promise
	return Promise.new(function(Resolve)
		local Connection = self:Connect(Event, Resolve)
		return Connection.Disconnect
	end)
end

export type Emitter = typeof(Emitter.new())

return Emitter
