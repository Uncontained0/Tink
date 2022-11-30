local Util = require(script.Parent.Parent.Util)
local Network = require(script.Parent.Parent.Network)

local ServiceList = {}

local Service = setmetatable({}, Util.Emitter)
Service.__index = Service

function Service.get(Name)
	if ServiceList[Name] then
		if ServiceList[Name] == true then
			repeat
				task.wait()
			until ServiceList[Name] ~= true
		end

		return ServiceList[Name]
	end

	local self = setmetatable({}, Service)

	Service.constructor(self, Name)

	return self
end

function Service:constructor(Name)
	ServiceList[Name] = true

	Util.Emitter.constructor(self)

	self._Name = Name

	local IdentifierPromise = Network.Serdes.Identifier(("TinkService_%s"):format(Name))

	task.delay(5, function()
		if self._Identifier == nil then
			warn(("It's taking a while to get service %s. Are you sure it exists?"):format(Name))
		end
	end)

	self._Identifier = IdentifierPromise:Await()
	
	self.Client = self

	self.Server = {}

	Network.Event.RegisterConnection(self._Name, function(Id, ...)
		local Name = Network.Serdes.Name(Id)

		self:Emit(Name, ...)
		
		if type(self.Server[Name]) == "function" then
			self.Server[Name](self, ...)
		end
	end)

	Network.Event.RegisterCallback(self._Name, function(Id, ...)
		local Name = Network.Serdes.Name(Id)

		if type(self.Server[Name]) == "function" then
			return self.Server[Name](self, ...)
		end

		return error(("No method %s exists on service %s"):format(Name, self._Name))
	end)

	ServiceList[Name] = self
end

function Service:Invoke(Name, ...)
	return Network.Event.Invoke(self._Identifier, 0, Network.Serdes.Identifier(Name):Await(), ...)
end

function Service:Fire(Name, ...)
	Network.Event.Fire(self._Identifier, 0, Network.Serdes.Identifier(Name):Await(), ...)
end

return Service
