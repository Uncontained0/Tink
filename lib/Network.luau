local Util = require(script.Parent.Util)

type Packet = {
	r: number,
	d: any,
}

local ServerNetwork = setmetatable({}, Util.Emitter)
ServerNetwork.__index = ServerNetwork

function ServerNetwork.new(parent, name)
	local self = setmetatable({}, ServerNetwork)

	ServerNetwork.constructor(self, parent, name)

	return self
end

function ServerNetwork:constructor(parent, name)
	Util.Emitter.constructor(self)

	self._event = Util.Make("RemoteEvent", {
		Name = name,
		Parent = parent,
	}) :: RemoteEvent

	self._event.OnServerEvent:Connect(function(player, packet)
		self:_handleIncomingPacket(player, packet)
	end)
end

function ServerNetwork:_handleIncomingPacket(player, packet: Packet)
	if type(packet) ~= "table" or type(packet.d) ~= "table" then
		return
	end

	if packet.r == 1 then -- simple event
		if type(packet.d.n) ~= "string" or type(packet.d.a) ~= "table" then
			return
		end

		self:emit(packet.d.n, player, unpack(packet.d.a))
	elseif packet.r == 2 then -- remote function
		if type(packet.d.n) ~= "string" or type(packet.d.a) ~= "table" then
			return
		end

		if type(self[packet.d.n]) ~= "function" then
			-- return missing function error
		end

		
	end
end