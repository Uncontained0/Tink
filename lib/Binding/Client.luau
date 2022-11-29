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

--[=[
	@class ClientBinding

	The client version of the binding class.
]=]
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

	--[=[
		@within ClientBinding
		@prop Instance Instance
		
		The instance that this binding is bound to.
	]=]
	self.Instance = Instance

	--[=[
		@within ClientBinding
		@prop Server { [string]: (...any) -> (...any) }
		
		The list of functions that the server can invoke on this binding.
		You can add functions here to add server functionality.

		```lua
		function Binding.Server:DoSomething()
			print("Server did something!")
		end
		```

		Just like all tables of the type, these can be invoked as remote events or
		remote functions.
	]=]
	self.Server = {}

	--[=[
		@within ClientBinding
		@prop Attributes { [string]: any }

		As attributes are commonly used as shared state between the
		server and client, this table is provided as a shortcut.
		Reading this table will return the attribute value, and
		Writing will set the attribute value. You can also iterate
		over this table to get all the attributes.

		```lua
		Binding.Attributes.Color = Color3.new(1, 0, 0)
		print(Binding.Attributes.Color)

		-- note that you **MUST** use general iteration
		-- to get all the attributes
		for i, v in Binding.Attributes do
			print(i, v)
		end
		```
	]=]
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

	if type(self.Start) == "function" then
		--[=[
			@within ClientBinding
			@method Start

			This method is called when the binding is attached
			to an instance.
		]=]
		self:Start()
	end
end

--[=[
	@within ClientBinding
	@method Fire
]=]
function Client:Fire(Name, ...)
	Network.Event.Fire(Id, 0, self.Instance, Network.Serdes.Identifier(Name):expect(), ...)
end

function Client:Invoke(Name, ...)
	return Network.Event.Invoke(Id, 0, self.Instance, Network.Serdes.Identifier(Name):expect(), ...)
end

function Client:_Destroying()
	BindingList[self.Instance] = nil

	self:Destroying()
end

--[=[
	@within ClientBinding
	@method Destroying
	
	Called when the instance is destroyed.
]=]
function Client:Destroying() end

return Client
