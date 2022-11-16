local Players = game:GetService("Players")

local Connection = {}
Connection.__index = Connection

function Connection.new(Event, Callback)
	local self = setmetatable({}, Connection)

	Connection.constructor(self, Event, Callback)

	return self
end

function Connection:constructor(Event, Callback)
	self._event = Event
	self._callback = Callback
end

function Connection:disconnect()
	if self._event._root == self then
		self._event._root = self._next
	else
		local current = self._event._root

		while current do
			if current._next == self then
				current._next = self._next
				break
			end

			current = current._next
		end
	end
end

local Event = {}
Event.__index = Event

function Event.new(Parent, Name)
	local self = setmetatable({}, Event)

	Event.constructor(self, Parent, Name)

	return self
end

function Event:constructor(Parent, Name)
	self._instance = Instance.new("RemoteEvent")
	self._instance.Name = Name
	self._instance.Parent = Parent

	self._root = nil

	self._instance.OnServerEvent:Connect(function(player, ...)
		local current = self._root

		while current do
			task.spawn(current._callback, player, ...)

			current = current._next
		end
	end)
end

function Event:fire(Player, ...)
	self._instance:FireClient(Player, ...)
end

function Event:fireAll(...)
	self._instance:FireAllClients(...)
end

function Event:fireAllExcept(Player, ...)
	for _, v in Players:GetPlayers() do
		if v ~= Player then
			self._instance:FireClient(v, ...)
		end
	end
end

function Event:fireClients(Players, ...)
	for _, v in Players do
		self._instance:FireClient(v, ...)
	end
end

function Event:connect(Callback)
	local connection = Connection.new(self, Callback)

	if self._root then
		connection._next = self._root
	end

	self._root = connection

	return connection
end

function Event:once(predicate, callback)
	local connection
	connection = self:connect(function(...)
		if callback ~= nil and predicate(...) then
			connection:disconnect()

			if callback ~= nil then 
				callback(...)
			else
				predicate(...)
			end
		end
	end)

	return connection
end

function Event:wait()
	local running = coroutine.running()

	self:once(function(...)
		coroutine.resume(running, ...)
	end)

	return coroutine.yield()
end

function Event:disconnectAll()
	local current = self._root

	while current do
		local next = current._next

		current:disconnect()

		current = next
	end
end

function Event:destroy()
	self:disconnectAll()

	self._instance:Destroy()
end

return Event
