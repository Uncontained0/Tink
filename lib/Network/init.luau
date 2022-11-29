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

--[=[
	@class Network

	This class contains all of the networking functionality of Tink.
	I do not suggest you use this directly, but instead use [Service] or [Binding].
	If you do use this directly, I highly suggest you read the code that powers
	it, as well as the documentation.
]=]

--[=[
	@prop Serdes Serdes
	@within Network
	
	A reference to the [Serdes] class.
]=]

--[=[
	@prop Event Event
	@within Network

	A reference to the [Event] class.
]=]

return {
	Serdes = Serdes,
	Event = Event,
}