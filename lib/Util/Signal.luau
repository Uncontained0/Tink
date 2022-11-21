local Promise = require(script.Parent.Parent.Parent.Promise)
local Spawn = require(script.Parent.Spawn)

local SignalConnection = {}
SignalConnection.__index = SignalConnection

function SignalConnection.new(signal, callback)
	local self = setmetatable({}, SignalConnection)
	
	SignalConnection.constructor(self, signal, callback)

	return self
end

function SignalConnection:constructor(signal, callback)
	self._signal = signal
	self._callback = callback
end

function SignalConnection:Disconnect()
	if self._signal._root == self then
		self._signal._root = self._next
	else
		local current = self._signal._root

		while current do
			if current._next == self then
				current._next = self._next
				break
			end

			current = current._next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({}, Signal)
end

function Signal:connect(callback)
	local connection = SignalConnection.new(self, callback)

	if self._root then
		connection._next = self._root
	end

	self._root = connection

	return connection
end

function Signal:wait()
	return Promise.new(function(resolve)
		local connection

		connection = self:connect(function(...)
			connection:Disconnect()
			resolve(...)
		end)
	end)
end

function Signal:fire(...)
	local current = self._root

	while current do
		Spawn(current._callback, ...)
		current = current._next
	end
end

return Signal