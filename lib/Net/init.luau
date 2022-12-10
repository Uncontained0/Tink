local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Util)

if Util.IsServer then
	Util.Make("RemoteEvent", {
		Name = "TinkNet",
		Parent = ReplicatedStorage,
	})
end

local Serdes = require(script.Serdes)
Serdes.Listen()

local Event = require(script.Event)
Event.Listen()

return {
	Serdes = Serdes,
	Event = Event,
}
