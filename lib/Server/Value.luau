local Players = game:GetService("Players")

local Value = {}
Value.__index = Value

function Value.new(Parent, Name)
	local self = setmetatable({}, Value)

	Value.constructor(self, Parent, Name)

	return self
end

function Value:constructor(Parent, Name)
	self._instance = Instance.new("RemoteEvent")
	self._instance.Name = Name
	self._instance.Parent = Parent

	self._values = {}
end

function Value:_send(player)
	local value = self._playerValues[player]

	if value then
		self._instance:FireClient(player, value)
	else
		self._instance:FireClient(player, self._value)
	end
end

function Value:set(value)
	self._value = value

	for _, v in Players:GetPlayers() do
		self:_send(v)
	end
end

function Value:setFor(player, value)
	self._playerValues[player] = value

	self:_send(player)
end

function Value:clearFor(player)
	self._playerValues[player] = nil

	self:_send(player)
end

function Value:get()
	return self._value
end

function Value:getFor(player)
	return self._playerValues[player] or self._value
end

return Value
