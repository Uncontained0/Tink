local Players = game:GetService("Players")

local Network = require(script.Parent.Parent.Network)

--[=[
	@class ServerService

	A service that can be accessed from the server.
]=]
local Service = {}
Service.__index = Service

--[=[
	@within ServerService
	@function new
	@param Name string
	@return ServerService

	Creates a new service with the given name. This service can be accessed from both the client and the server.
	Services can be created from the server only, at any time.

	:::danger
	Creating duplicate services will result in undefined behavior, but if you know what you're doing
	you can use this to your advantage.
	:::
]=]
function Service.new(Name)
	local self = setmetatable({}, Service)

	Service.constructor(self, Name)

	return self
end

function Service:constructor(Name)
	self._Name = Name
	self._Identifier = Network.Serdes.Identifier(("TinkService_%s"):format(Name)):Await()

	--[=[
		@within ServerService
		@prop Client {[string]: (...any) -> (...any)}

		A table of methods exposed to the clients. If a client calls a remote event,
		then the return from the method will be ignored. If a client calls a remote
		function, then the return will be sent back to the client.

		```lua
		-- remote function
		function MyService.Client:GetMoney(Player)
			return self:GetMoney(Player)
		end

		-- remote event
		function MyService.Client:GiveMoney(Player, To, Amount)
			self:GiveMoney(Player, To, Amount)
		end
		```
	]=]
	self.Client = setmetatable({}, {
		__newindex = function(t, i, v)
			Network.Serdes.Identifier(i)

			rawset(t, i, v)
		end
	})

	--[=[
		@within ServerService
		@prop Server ServerService

		A reference back to the service. This exists for an easier transition
		from Knit.
	]=]
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

--[=[
	@within ServerService
	@method FireTo
	@param Player Player -- The player to fire the event to.
	@param Name string -- The name of the event to fire.
	@param ... any -- The arguments to pass to the event.

	Fires an event to the given player.

	```lua
	MyService:FireTo(Player, "MoneyValue", 100)
	```
]=]
function Service:FireTo(Player, Name, ...)
	Network.Event.Fire(self._Name, Player, Network.Serdes.Identifier(Name):Await(), ...)
end

--[=[
	@within ServerService
	@method FireAll
	@param Name string -- The name of the event to fire.
	@param ... any -- The arguments to pass to the event.

	Fires an event to all players.

	```lua
	MyService:FireAll("RoundStart")
	```
]=]
function Service:FireAll(Name, ...)
	for _, Player in Players:GetPlayers() do
		self:FireTo(Player, Name, ...)
	end
end

--[=[
	@within ServerService
	@method FireExcept
	@param Player Player -- The player to not fire the event to.
	@param Name string -- The name of the event to fire.
	@param ... any -- The arguments to pass to the event.

	Fires an event to all players except the given player.

	```lua
	MyService:FireExcept(Player, "RoundStart")
	```
]=]
function Service:FireAllExcept(Player, Name, ...)
	for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer ~= Player then
			self:FireTo(OtherPlayer, Name, ...)
		end
	end
end

--[=[
	@within ServerService
	@method Invoke
	@param Player Player -- The player to invoke the function on.
	@param Name string -- The name of the function to invoke.
	@param ... any -- The arguments to pass to the function.
	@return Promise<any>

	Invokes a function on the given player.

	:::danger
	Invoking a function on a client has the chance to never return
	for many reasons. Always use a timeout when invoking a function.
	:::
]=]
function Service:Invoke(Player, Name, ...)
	return Network.Event.Invoke(self._Name, Player, Network.Serdes.Identifier(Name):Await(), ...)
end

return Service
