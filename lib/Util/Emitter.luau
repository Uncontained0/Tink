local Spawn = require(script.Parent.Spawn)
local Promise = require(script.Parent.Promise)

local Connection = {}
Connection.__index = Connection

function Connection.Connection(Emitter: Emitter, Event: string, Callback: (any) -> any)
	local self = setmetatable({}, Connection)

	self.Emitter = Emitter
	self.Event = Event
	self.Callback = Callback
	self.Next = nil :: Connection?

	return self
end

Connection.new = Connection.Connection

function Connection.Disconnect(self: Connection)
	if self.Emitter.Root[self.Event] == self then
		self.Emitter.Root[self.Event] = self.Next
	else
		local Current = self.Emitter.Root[self.Event]

		while Current do
			if Current.Next == self then
				Current.Next = self.Next
				break
			end

			Current = Current.Next
		end
	end
end

export type Connection = typeof(Connection.Connection(...))

local Emitter = {}
Emitter.__index = Emitter

function Emitter.Emitter()
	local self = setmetatable({}, Emitter)

	self.Root = {}

	return self
end

Emitter.new = Emitter.Emitter :: () -> Emitter

function Emitter.Connect(self: Emitter, Event: string, Callback: (...any) -> ())
	local Connection = Connection.Connection(self, Event, Callback)

	Connection.Next = self.Root[Event]
	self.Root[Event] = Connection

	return Connection
end

Emitter.On = Emitter.Connect

function Emitter.Fire(self: Emitter, Event: string, ...)
	local Current = self.Root[Event]

	while Current do
		Spawn(Current.Callback, ...)

		Current = Current.Next
	end
end

Emitter.Emit = Emitter.Fire

function Emitter.Wait(self: Emitter, Event: string)
	return Promise.new(function(Resolve)
		local Connection
		Connection = self:Connect(Event, function(...)
			Connection.Disconnect()
			Resolve(...)
		end)
	end)
end

export type Emitter = typeof(Emitter.Emitter(...))

return Emitter
