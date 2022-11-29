local Util = require(script.Parent.Parent.Util)
local Network = require(script.Parent.Parent.Network)

local ServiceList = {}

--[=[
	@class ClientService

	A client interface for services on the server.
]=]
local Service = setmetatable({}, Util.Emitter)
Service.__index = Service

--[=[
	@within ClientService
	@function get
	@param Name string
	@return ClientService

	Gets a service with the given name. This will yield until the service exists.
	If this process takes longer than 5 seconds, it will throw a warning.
]=]
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

	self._Identifier = IdentifierPromise:expect()

	--[=[
		@within ClientService
		@prop Client ClientService
		@readonly

		A reference to the clientservice itself. This is to ease the
		transition from Knit to Tink.
	]=]
	self.Client = self

	--[=[
		@within ClientService
		@prop Server { [string]: (...any) -> (...any) }

		Functions can be added as strings to this table, and the server will be able to call them.
		These functions are triggered both by events, and invokes.

		```lua
		-- Server
		print(MyService:Invoke(Player1, "Greetings"):expect())

		-- Client
		function MyService.Server:Greetings()
			return "Hello world!"
		end
		```

		:::tip
		Unlike Knit, the context for self in these functions is the service itself.
		To help transition, `self.Client` refers to the client service.
		:::
	]=]
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

--[=[
	@within ClientService
	@method Invoke
	@param Name string -- The remote function to invoke
	@param ... any -- The arguments to pass to the remote function
	@return Promise<any> -- The result of the remote function

	Invokes a remote function on the server. This returns a promise
	that yields until the remote function returns.

	```lua
	ClientService:Invoke("GetMoney"):andThen(function(Money)
		print(("You have %d money!"):format(Money))
	end)
	```
]=]
function Service:Invoke(Name, ...)
	return Network.Event.Invoke(self._Identifier, 0, Network.Serdes.Identifier(Name):expect(), ...)
end

--[=[
	@within ClientService
	@method Fire
	@param Name string -- The remote event to fire
	@param ... any -- The arguments to pass to the remote event

	Fires a remote event on the server. This returns nothing.

	```lua
	ClientService:Fire("GiveMoney", Player2, 100)
	```
]=]
function Service:Fire(Name, ...)
	Network.Event.Fire(self._Identifier, 0, Network.Serdes.Identifier(Name):expect(), ...)
end

--[=[
	@within ClientService
	@method On
	@param Name string -- The remote event to listen to
	@param Callback (...any) -> () -- The callback to call when the remote event is fired
	@return EmitterConnection

	On the client it is sometimes necessary to connect multiple listeners to the same event.
	To do this, use the `On` method instead of putting a function in the `Server` table that
	just calls more functions.

	```lua
	local Connection = ClientService:On("MoneyGiven", function(Player, Money)
		print(("%s was given %d money!"):format(Player.Name, Money))
	end)

	Connection:Disconnect()
	```
]=]

--[=[
	@within ClientService
	@method Wait
	@param Name string -- The remote event to wait for
	@return Promise<any>

	Waits for a remote event to fire. This returns a promise
	that resolves with the arguments passed to the next fire
	of the remote event.

	```lua
	ClientService:Wait("MoneyGiven"):andThen(function(Player, Money)
		print(("%s was given %d money!"):format(Player.Name, Money))
	end)
	```
]=]

return Service
