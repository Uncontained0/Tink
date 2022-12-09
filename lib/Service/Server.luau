local Util = require(script.Parent.Parent.Util)
local Net = require(script.Parent.Parent.Net)

local Server = setmetatable({}, Util.Emitter)
Server.__index = Server

function Server.new(Name: string)
	local self = setmetatable({}, Server)

	self.Root = {}

	self.Name = Name
	self.Server = self

	self.Client = (setmetatable({}, {
		__newindex = function(t, i, v)
			Net.Serdes.Identifier(self.Name .. ":" .. i)
			rawset(t, i, v)
		end
	}) :: any) :: { [string]: (...unknown) -> (...any) }

	return self
end

export type Server = typeof(Server.new(table.unpack(...)))