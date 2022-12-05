local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Parent.Util)
local Serdes = require(script.Parent.Serdes)
local Promise = Util.Promise

local Event = {
	Instance = ReplicatedStorage:WaitForChild("Tink") :: RemoteEvent,
	Listening = false,

	IncomingQueue = {} :: { {
		Remote: string,
		Action: string,
		Args: { any },
		Player: Player?,
	} },
	OutboundQueue = {} :: {
		[Player]: {
			[string]: { { any } },
		},
	},

	Callbacks = {},
	Connections = {},

	ActiveInvokes = {},

	NilId = Serdes.Identifier("TinkNil"):Await(),
	EventId = Serdes.Identifier("TinkEvent"):Await(),
	InvokeId = Serdes.Identifier("TinkInvoke"):Await(),
	InvokeReturnId = Serdes.Identifier("TinkInvokeReturn"):Await(),
}

function Event.Listen()
	assert(not Event.Listening, "Event.Listen can only be called once")

	if Util.IsServer then
		Event.Instance.OnServerEvent:Connect(function(Player, Packets)
			for Remote, Packets in Packets do
				for _, Packet in Packets do
					local Args = Packet
					local Action = table.remove(Args, 1) :: string

					if type(Action) ~= "string" then
						continue
					end

					for i, v in Args do
						if v == Event.NilId then
							Args[i] = nil
						end
					end

					table.insert(Event.IncomingQueue, {
						Player = Player,
						Remote = Serdes.Name(Remote),
						Action = Action,
						Args = Args,
					})
				end
			end
		end)
	else
		Event.Instance.OnClientEvent:Connect(function(Packets)
			for Remote, Packets in Packets do
				for _, Packet in Packets do
					local Args = Packet
					local Action = table.remove(Args, 1) :: string

					if type(Action) ~= "string" then
						continue
					end

					for i, v in Args do
						if v == Event.NilId then
							Args[i] = nil
						end
					end

					table.insert(Event.IncomingQueue, {
						Remote = Serdes.Name(Remote),
						Action = Action,
						Args = Args,
					})
				end
			end
		end)
	end

	Event.Listening = true
end

function Event.ProcessQueue()
	debug.profilebegin("Event.IncomingProcessQueue")

	for _, v in Event.IncomingQueue do
		Event.ProcessIncomingPacket(v)
	end

	table.clear(Event.IncomingQueue)

	debug.profileend()
	debug.profilebegin("Event.OutboundProcessQueue")

	for Player, Packets in Event.OutboundQueue do
		Event.ProcessOutboundPackets(Player, Packets)
	end

	table.clear(Event.OutboundQueue)

	debug.profileend()
end

function Event.ProcessIncomingPacket(Packet)
	if Packet.Action == Event.InvokeId then
		Event._InvokeCallback(Packet)
	elseif Packet.Action == Event.EventId then
		Event._FireConnections(Packet)
	elseif Packet.Action == Event.InvokeReturnId then
		Event._ReturnInvoke(Packet)
	end
end

function Event.ProcessOutboundPackets(Player: Player | number, Packets)
	if Util.IsServer then
		Event.Instance:FireClient(Player :: Player, Packets)
	elseif Player == 0 then
		Event.Instance:FireServer(Packets)
	end
end

function Event._InvokeCallback(Packet)
	local Source = Packet.Player or 0 :: Player | number
	local Callback = Event.Callbacks[Packet.Remote]

	local Args
	if Packet.Player then
		Args = { Packet.Player, table.unpack(Packet.Args) }
	else
		Args = Packet.Args
	end

	if Callback then
		Util.Spawn(function()
			Event._Send(
				Source,
				Serdes.Identifier(Packet.Remote):Await(),
				table.pack(Event.InvokeReturn, pcall(Callback, unpack(Args)))
			)
		end)
	else
		Util.Spawn(function()
			Event._Send(
				Source,
				Serdes.Identifier(Packet.Remote):Await(),
				table.pack(Event.InvokeReturn, false, "No callback registered for " .. Packet.Remote)
			)
		end)
	end
end

function Event._Send(To, Remote, Data)
	if Event.OutboundQueue[To] == nil then
		Event.OutboundQueue[To] = {}
	end

	if Event.OutboundQueue[To][Remote] == nil then
		Event.OutboundQueue[To][Remote] = {}
	end

	table.insert(Event.OutboundQueue[To][Remote], Data)
end

function Event.Invoke(Remote, To, ...): Util.Promise
	Remote = Serdes.Identifier(Remote):Await()
	local InvokeId = Serdes.UUID()
	local Args = table.pack(Event.Invoke, Serdes.PackUUID(InvokeId), ...)

	for i, v in Args do
		if v == nil then
			Args[i] = Event.Nil
		end
	end

	Event._Send(To, Remote, Args)

	return Promise.new(function(Resolve, Reject)
		Event.ActiveInvokes[InvokeId] = {
			Resolve = Resolve,
			Reject = Reject,
		}
	end):Finally(function()
		Event.ActiveInvokes[InvokeId] = nil
	end)
end

function Event.Fire(Remote, To, ...)
	Remote = Serdes.Identifier(Remote):Await()
	local Args = table.pack(Event.Event, ...)

	for i, v in Args do
		if v == nil then
			Args[i] = Event.Nil
		end
	end

	Event._Send(To, Remote, Args)
end

function Event._ReturnInvoke(Packet)
	local InvokeId = table.remove(Packet.Args, 1) :: string
	if type(InvokeId) == "string" then
		InvokeId = Serdes.UnpackUUID(InvokeId)
	else
		return
	end

	local Invoke = Event.ActiveInvokes[InvokeId]

	if Invoke then
		if table.remove(Packet.Args, 1) then
			Invoke.Resolve(unpack(Packet.Args))
			Event.ActiveInvokes[InvokeId] = nil
		elseif type(Packet.Args[1]) == "string" then
			Invoke.Reject(table.remove(Packet.Args, 1) :: string)
			Event.ActiveInvokes[InvokeId] = nil
		else
			Invoke.Reject("Unknown error")
			Event.ActiveInvokes[InvokeId] = nil
		end
	else
		warn("Received an invoke return for an unknown invoke")
	end
end

function Event._FireConnections(Packet)
	local Connections = Event.Connections[Packet.Remote]

	if Connections then
		for _, Connection in Connections do
			Util.Spawn(Connection, Packet.Player, unpack(Packet.Args))
		end
	end
end

function Event.RegisterCallback(Remote, Callback)
	assert(type(Callback) == "function", "Callback must be a function")

	Event.Callbacks[Remote] = Callback
end

function Event.RegisterConnection(Remote, Callback)
	assert(type(Callback) == "function", "Callback must be a function")

	if Event.Connections[Remote] == nil then
		Event.Connections[Remote] = {}
	end

	table.insert(Event.Connections[Remote], Callback)
end

return Event
