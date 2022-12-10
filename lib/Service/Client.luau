local Util = require(script.Parent.Parent.Util)
local Net = require(script.Parent.Parent.Net)

local Client = setmetatable({}, Util.Emitter)
Client.__index = Client

function Client.Client(Name: string)
	local self = setmetatable({}, Client)

	self.Root = {}

	self.Name = Name

	Net.Event.On(self.Name, function(EventId, ...)
		local EventName = Net.Serdes.Name(EventId :: string)

		if EventName == nil then
			return
		end

		Util.Emitter.Emit(self :: any, EventName, ...)
	end)

	return self
end

Client.new = Client.Client :: (Name: string) -> Client

function Client.Invoke(self: Client, Event: string, ...)
	return Net.Event.Invoke("Server", self.Name, Net.Serdes.Identifier(Event):Await(), ...)
end

function Client.Fire(self: Client, Event: string, ...)
	return Net.Event.FireTo("Server", self.Name, Net.Serdes.Identifier(Event):Await(), ...)
end

export type Client = typeof(Client.Client(...))

return Client
