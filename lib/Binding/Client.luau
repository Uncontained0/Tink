local Util = require(script.Parent.Parent.Util)
local Network = require(script.Parent.Parent.Network)

local Id = Network.Serdes.Identifier("TinkBinding")

local BindingList = {}

Network.Event.RegisterCallback(Id, function(Instance, Id, ...)
	local Binding = BindingList[Instance]
	local Name = Network.Serdes.Name(Id)

	if Binding then
		if type(Binding.Client[Name]) == "function" then
			return Binding.Server[Name](Binding, ...)
		else
			return error("Callback " .. Name .. " doesn't exist.")
		end
	else
		return error("Binding doesn't exist.")
	end
end)

Network.Event.RegisterConnection(Id, function(Instance, Id, ...)
	local Binding = BindingList[Instance]
	local Name = Network.Serdes.Name(Id)

	if Binding then
		if type(Binding.Client[Name]) == "function" then
			Binding.Server[Name](Binding, ...)
		end
	end
end)

local Client = {}
Client.__index = Client

function Client.get(Instance)
	return BindingList[Instance]
end

function Client.new(Instance)
	local self = setmetatable({}, Client)

	Client.constructor(self, Instance)

	return self
end

function Client:constructor(Instance)
	assert(BindingList[Instance] == nil, "Binding already exists for this instance")

	BindingList[Instance] = self
	self.Instance = Instance

	self.Server = {}

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

function Client:Fire(Name, ...)
	Network.Event.Fire(Id, self.Instance, Network.Serdes.Identifier(Name):expect(), ...)
end

function Client:Invoke(Name, ...)
	return Network.Event.Invoke(Id, self.Instance, Network.Serdes.Identifier(Name):expect(), ...)
end

function Client:_Destroying()
	BindingList[self.Instance] = nil

	self:Destroying()
end

function Client:Destroying() end

return Client
