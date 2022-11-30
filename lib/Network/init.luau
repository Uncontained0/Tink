local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Util = require(script.Parent.Util)

Util.Make("RemoteEvent", {
	Name = "Tink",
	Parent = ReplicatedStorage,
}, {
	Util.Make("Folder", {
		Name = "Serdes",
	}),
})

local Serdes = require(script.Serdes)
local Event = require(script.Event)

if not Util.IsServer then
	Serdes.Listen()
	Event.Listen()
	
	RunService.Heartbeat:Connect(function()
		Event.ProcessQueue()
	end)
end




return {
	Serdes = Serdes,
	Event = Event,
}