local Players = game:GetService("Players")

local Network = require(script.Parent.Parent.Network)

local Service = {}
Service.__index = Service

function Service.new(Name)
	local self = setmetatable({}, Service)

	Service.constructor(self, Name)

	return self
end

function Service:constructor(Name)
	self._Name = Name
	self._Identifier = Network.Serdes.Identifier(("TinkService_%s"):format(Name)):expect()

	self.Client = setmetatable({}, {
		__newindex = function(t, i, v)
			Network.Serdes.Identifier(i)

			rawset(t, i, v)
		end
	})

	self.Server = self

	Network.Event.RegisterCallback(self._Name, function(Player, Id, ...)
		local Name = Network.Serdes.Name(Id)

		if type(self.Client[Name]) == "function" then
			return self.Client[Name](self, Player, ...)
		else
			return error(("Service %s does not have a client method %s"):format(self._Name, Name))
		end
	end)

	Network.Event.RegisterConnection(self._Name, function(Player, Id, ...)
		local Name = Network.Serdes.Name(Id)

		if type(self.Client[Name]) == "function" then
			self.Client[Name](self, Player, ...)
		end
	end)
end

function Service:FireTo(Player, Name, ...)
	Network.Event.Fire(self._Name, Player, Network.Serdes.Identifier(Name):expect(), ...)
end

function Service:FireAll(Name, ...)
	for _, Player in Players:GetPlayers() do
		self:FireTo(Player, Name, ...)
	end
end

function Service:FireAllExcept(Player, Name, ...)
	for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer ~= Player then
			self:FireTo(OtherPlayer, Name, ...)
		end
	end
end

function Service:Invoke(Player, Name, ...)
	return Network.Event.Invoke(self._Name, Player, Network.Serdes.Identifier(Name):expect(), ...)
end

return Service
