local Players = game:GetService("Players")

local Util = require(script.Parent.Parent.Util)
local Network = require(script.Parent.Parent.Network)

local Id = Network.Serdes.Identifier("TinkBinding")

local BindingList = {}

Network.Event.RegisterCallback(Id, function(Player, Instance, Id, ...)
	local Binding = BindingList[Instance]
	local Name = Network.Serdes.Name(Id)

	if Binding then
		if type(Binding.Client[Name]) == "function" then
			return Binding.Client[Name](Binding, Player, ...)
		else
			return error("Callback " .. Name .. " doesn't exist.")
		end
	else
		return error("Binding doesn't exist.")
	end
end)

Network.Event.RegisterConnection(Id, function(Player, Instance, Id, ...)
	local Binding = BindingList[Instance]
	local Name = Network.Serdes.Name(Id)

	if Binding then
		if type(Binding.Client[Name]) == "function" then
			Binding.Client[Name](Binding, Player, ...)
		end
	end
end)

local Server = {}
Server.__index = Server

function Server.get(Instance)
	return BindingList[Instance]
end

function Server.new(Instance)
	local self = setmetatable({}, Server)

	Server.constructor(self, Instance)

	return self
end

function Server:constructor(Instance: Instance)
	assert(BindingList[Instance] == nil, "Binding already exists for this instance")

	BindingList[Instance] = self
	self.Instance = Instance

	self.Client = setmetatable({}, {
		__newindex = function(t, i, v)
			Network.Serdes.Identifier(i)

			rawset(t, i, v)
		end,
	})

	self.Attributes = setmetatable({}, {
		__newindex = function(_, i, v)
			self.Instance:SetAttribute(i, v)
		end,

		__index = function(_, i)
			return self.Instance:GetAttribute(i)
		end,

		__iter = function()
			return ipairs(self.Instance:GetAttributes())
		end,
	})

	Instance.Destroying:Connect(Util.Wrap(self._Destroying, self))

	if self.Start then
		self:Start()
	end
end

function Server:FireTo(Player, Name, ...)
	Network.Event.Fire(Id, Player, self.Instance, Network.Serdes.Identifier(Name):await(), ...)
end

function Server:FireAll(Name, ...)
	for _, Player in Players:GetPlayers() do
		self:FireTo(Player, Name, ...)
	end
end

function Server:FireAllExcept(Player, Name, ...)
	for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer ~= Player then
			self:FireTo(OtherPlayer, Name, ...)
		end
	end
end

function Server:Invoke(Player, Name, ...)
	return Network.Event.Invoke(Id, Player, self.Instance, Network.Serdes.Identifier(Name):await(), ...)
end

function Server:_Destroying()
	BindingList[self.Instance] = nil

	self:Destroying()
end

function Server:Destroying() end

return Server
