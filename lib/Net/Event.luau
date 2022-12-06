local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Parent.Util)
local Serdes = require(script.Parent.Serdes)

local Event = {
	Instance = ReplicatedStorage:WaitForChild("TinkNet") :: RemoteEvent,

	NilId = Serdes.Identifier("TinkNil"):Await(),

	EventId = Serdes.Identifier("TinkEvent"):Await(),
	InvokeId = Serdes.Identifier("TinkInvoke"):Await(),
	InvokeReturnId = Serdes.Identifier("TinkInvokeReturn"):Await(),
	
}