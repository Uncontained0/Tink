local Promise = require(script.Parent.Parent.Parent.Promise)

local EmitterConnection = {}
EmitterConnection.__index = EmitterConnection

function EmitterConnection.new(emitter, event, callback)
	local self = setmetatable({}, EmitterConnection)
	
	EmitterConnection.constructor(self, emitter, event, callback)

	return self
end

function EmitterConnection:constructor(emitter, event, callback)
	self._emitter = emitter
	self._event = event
	self._callback = callback
end

function EmitterConnection:Disconnect()
	if self._emitter._root[self._event] == self then
		self._emitter._root[self._event] = self._next
	else
		local current = self._emitter._root[self._event]

		while current do
			if current._next == self then
				current._next = self._next
				break
			end

			current = current._next
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
	self._root = {}
end

function Emitter:on(event, callback)
	local connection = EmitterConnection.new(self, event, callback)

	if self._root[event] then
		connection._next = self._root[event]
	end

	self._root[event] = connection

	return connection
end

function Emitter:wait(event)
	return Promise.new(function(resolve)
		local connection

		connection = self:on(event, function(...)
			connection:Disconnect()
			resolve(...)
		end)
	end)
end

function Emitter:emit(event, ...)
	local current = self._root[event]

	while current do
		current._callback(...)
		current = current._next
	end
end

return Emitter