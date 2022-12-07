local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Parent.Util)
local Serdes = require(script.Parent.Serdes)

local Event = {
	Instance = ReplicatedStorage:WaitForChild("TinkNet") :: RemoteEvent,

	IncomingQueue = {},
	OutboundQueue = {},

	NilId = Serdes.Identifier("TinkNil"):Await(),
	EventId = Serdes.Identifier("TinkEvent"):Await(),
	InvokeId = Serdes.Identifier("TinkInvoke"):Await(),
	InvokeReturnId = Serdes.Identifier("TinkInvokeReturn"):Await(),

	Emitter = Util.Emitter.new(),
	Callbacks = {},
}

type Packet = {
	Event: string,
	Type: string,
	Player: Player?,
	Args: { unknown },
}

function Event.HandlePackets(Packets: { Packet })
	for _, Packet in Packets do
		if Packet.Type == Event.EventId then
			if Packet.Player then
				Event.Emitter:Emit(Packet.Event, Packet.Player, unpack(Packet.Args))
			else
				Event.Emitter:Emit(Packet.Event, unpack(Packet.Args))
			end
		elseif Packet.Type == Event.InvokeId then
			Util.Spawn(function()
				
			end)
		end
	end
end

function Event.HandleEvent(Packet: Packet)
	
end
