local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Util)

Util.Make("RemoteEvent", {
	Name = "TinkNet",
	Parent = ReplicatedStorage,
})

local Serdes = require(script.Serdes)
Serdes.Listen()

local Event = require(script.Event)
Event.Listen()

return {
	Serdes = Serdes,
	Event = Event,
}