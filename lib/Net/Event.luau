local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Parent.Util)
local Serdes = require(script.Parent.Serdes)

type NetworkTarget = Player | "Server"

type Packet = {
	Event: string,
	Type: string,
	Player: NetworkTarget,
	Args: { unknown },
}

local Event = {
	Instance = ReplicatedStorage:WaitForChild("TinkNet") :: RemoteEvent,

	IncomingQueue = {} :: { Packet },
	OutboundQueue = {} :: { [NetworkTarget]: { [string]: { [string]: { any } } } },

	NilId = Serdes.Identifier("TinkNil"):Await(),
	EventId = Serdes.Identifier("TinkEvent"):Await(),
	InvokeId = Serdes.Identifier("TinkInvoke"):Await(),
	InvokeReturnId = Serdes.Identifier("TinkInvokeReturn"):Await(),

	Emitter = Util.Emitter.new(),
	Callbacks = {} :: { [string]: (...unknown) -> (...any) },

	ActiveCalls = {} :: { [NetworkTarget]: { [string]: thread } },
}

function Event.Listen()
	if Util.IsServer then
		Event.Instance.OnServerEvent:Connect(function(Player, Packets)
			if type(Packets) ~= "table" then
				return
			end

			for EventId, Types in Packets do
				local EventName = Serdes.Name(EventId)

				for Type, Packets in Types do
					for _, Packet in Packets do
						table.insert(Event.IncomingQueue, {
							Event = EventName,
							Type = Type,
							Player = Player,
							Args = Packet,
						})
					end
				end
			end
		end)
	else
		Event.Instance.OnClientEvent:Connect(function(Packets)
			for EventId, Types in Packets do
				local EventName = Serdes.Name(EventId)

				for Type, Packets in Types do
					for _, Packet in Packets do
						table.insert(Event.IncomingQueue, {
							Event = EventName,
							Type = Type,
							Player = "Server",
							Args = Packet,
						})
					end
				end
			end
		end)
	end
end

function Event.EmptyQueue()
	for _, Packet in Event.IncomingQueue do
		if Packet.Type == Event.EventId then
			if Packet.Player then
				Event.Emitter:Emit(Packet.Event, Packet.Player, unpack(Packet.Args))
			else
				Event.Emitter:Emit(Packet.Event, unpack(Packet.Args))
			end
		elseif Packet.Type == Event.InvokeId then
			Util.Spawn(function()
				if Event.Callbacks[Packet.Event] == nil then
					Event.Send(Packet.Player, Packet.Event, Event.InvokeReturnId, false, "Callback not found")

					return
				end

				Event.Send(
					Packet.Player,
					Packet.Event,
					Event.InvokeReturnId,
					pcall(Event.Callbacks[Packet.Event], Packet.Player, unpack(Packet.Args))
				)
			end)
		elseif Packet.Type == Event.InvokeReturnId then
			local Id = table.remove(Packet.Args, 1)
			local Thread = Event.ActiveCalls[Packet.Player][Id :: any]

			if Thread then
				Event.ActiveCalls[Packet.Player][Id :: any] = nil
				coroutine.resume(Thread, unpack(Packet.Args))
			end
		end
	end

	table.clear(Event.IncomingQueue)

	for Player, Packets in Event.OutboundQueue do
		if typeof(Player) == "Player" then
			Event.Instance:FireClient(Player, Packets)
		else
			Event.Instance:FireServer(Packets)
		end
	end

	table.clear(Event.OutboundQueue)
end

function Event.Send(Player: NetworkTarget, EventName: string, Type: string, ...: any)
	if Event.OutboundQueue[Player] == nil then
		Event.OutboundQueue[Player] = {}
	end

	EventName = Serdes.Identifier(EventName):Await()

	if Event.OutboundQueue[Player][EventName] == nil then
		Event.OutboundQueue[Player][EventName] = {}
	end

	if Event.OutboundQueue[Player][EventName][Type] == nil then
		Event.OutboundQueue[Player][EventName][Type] = {}
	end

	table.insert(Event.OutboundQueue[Player][EventName][Type], table.pack(...))
end

function Event.SetCallback(EventName: string, Callback: (...unknown) -> (...any))
	Event.Callbacks[EventName] = Callback
end

function Event.On(EventName: string, Callback: (...unknown) -> (...any))
	return Event.Emitter:On(EventName, Callback)
end

function Event.FireTo(Player: NetworkTarget, EventName: string, ...)
	Event.Send(Player, EventName, Event.EventId, ...)
end

function Event.Invoke(Player: NetworkTarget, EventName: string, ...)
	local Args = { ... }

	return Util.Promise.new(function(Resolve, Reject)
		local Id = Serdes.OneTimeId()

		if Event.ActiveCalls[Player] == nil then
			Event.ActiveCalls[Player] = {}
		end

		Event.ActiveCalls[Player][Id] = coroutine.running()
		Event.Send(Player, EventName, Event.InvokeId, Id, unpack(Args))

		local Values = table.pack(coroutine.yield() :: unknown)

		if table.remove(Values, 1) then
			Resolve(unpack(Values))
		elseif type(Values[1]) == "string" then
			Reject(Values[1] :: string)
		else
			Reject("Malformed response")
		end
	end)
end

return Event
