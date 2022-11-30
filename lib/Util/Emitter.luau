local Promise = require(script.Parent.Promise)
local Spawn = require(script.Parent.Spawn)

local EmitterConnection = {}
EmitterConnection.__index = EmitterConnection

function EmitterConnection.new(Emitter, Event, Callback)
	local self = setmetatable({}, EmitterConnection)
	
	EmitterConnection.constructor(self, Emitter, Event, Callback)

	return self
end

function EmitterConnection:constructor(Emitter, Event, Callback)
	self._Emitter = Emitter
	self._Event = Event
	self._Callback = Callback
end

function EmitterConnection:Disconnect()
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

local Emitter = {}
Emitter.__index = Emitter

function Emitter.new()
	local self = setmetatable({}, Emitter)

	Emitter.constructor(self)

	return self
end

function Emitter:constructor()
	self._Root = {}
end

function Emitter:On(Event, Callback)
	local Connection = EmitterConnection.new(self, Event, Callback)

	if self._Root[Event] then
		Connection._Next = self._Root[Event]
	end

	self._Root[Event] = Connection

	return Connection
end

function Emitter:Wait(Event)
	return Promise.new(function(resolve)
		local Connection

		Connection = self:on(Event, function(...)
			Connection:Disconnect()
			resolve(...)
		end)
	end)
end

function Emitter:Emit(Event, ...)
	local Current = self._Root[Event]

	if Current == nil then
		warn(("Event %s was emitted, but there were no listeners"):format(Event))
		return
	end

	while Current do
		Spawn(Current._Callback, ...)
		Current = Current._Next
	end
end

return Emitter