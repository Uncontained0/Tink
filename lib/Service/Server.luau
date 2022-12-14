local Players = game:GetService("Players")

local Util = require(script.Parent.Parent.Util)
local Net = require(script.Parent.Parent.Net)

local Server = setmetatable({}, Util.Emitter)
Server.__index = Server

function Server.Server(Name: string)
	local self = setmetatable({}, Server)

	self.Root = {}

	self.Name = Name
	self.Server = self

	self._Client = {} :: { [string]: (self: Server, Player: Player, ...unknown) -> (...any) }

	Net.Event.On(self.Name, function(Player, EventId, ...)
		if type(EventId) ~= "string" then
			return
		end

		local Event = Net.Serdes.Name(EventId :: string)

		if Event == nil then
			return
		end

		if self._Client[Event] then
			self._Client[Event](self, Player :: Player, ...)
		end

		Util.Emitter.Emit(self :: any, Event, Player, ...)
	end)

	Net.Event.SetCallback(self.Name, function(Player, EventId, ...)
		if type(EventId) ~= "string" then
			return
		end

		local Event = Net.Serdes.Name(EventId :: string)

		if Event == nil then
			return
		end

		if self._Client[Event] then
			return self._Client[Event](self, Player :: Player, ...)
		else
			return error("No function registered for event " .. Event)
		end
	end)

	return self
end

Server.new = Server.Server :: (Name: string) -> Server

function Server.Client(self: Server, Event: string, Callback: (self: Server, Player: Player, ...unknown) -> (...any))
	(self :: any)._Client[Event] = Callback
	Net.Serdes.Identifier(Event)
end

function Server.FireTo(self: Server, Player: Player, Event: string, ...)
	Net.Event.FireTo(Player, self.Name, Net.Serdes.Identifier(Event):Await(), ...)
end

function Server.FireAll(self: Server, Event: string, ...)
	for _, Player in Players:GetPlayers() do
		self:FireTo(Player, Event, ...)
	end
end

function Server.FireExcept(self: Server, Player: Player, Event: string, ...)
	for _, OtherPlayer in Players:GetPlayers() do
		if OtherPlayer ~= Player then
			self:FireTo(OtherPlayer, Event, ...)
		end
	end
end

export type Server = typeof(Server.Server(table.unpack(...)))

return Server
