local CollectionService = game:GetService("CollectionService")

local Util = require(script.Parent.Util)

local Server = require(script.Server)
local Client = require(script.Client)

--[=[
	@class Binding

	A binding is an object attached to an instance, that can communicate with the server
	and client.
]=]
local Binding = {}

--[=[
	@within Binding
	@function Create
	@return ServerBinding|ClientBinding
	
	Creates a new binding that you can then add methods and properties to.
]=]
function Binding.Create()
	if Util.IsServer then
		return setmetatable({}, Server)
	else
		return setmetatable({}, Client)
	end
end

--[=[
	@within Binding
	@function Bind
	@param Tag string -- The CollectionService tag to bind to.
	@param Binding ServerBinding|ClientBinding -- The binding to bind to the tag.

	This function binds a binding to a CollectionService tag. This
	should only be called once a binding has been fully setup.

	```lua
	local Bind = Binding.Create()

	-- add methods

	Binding.Bind("MyTag", Bind)
	```
]=]
function Binding.Bind(Tag, Binding)
	for _, v in CollectionService:GetTagged(Tag) do
		Util.Spawn(Binding.new, v)
	end

	CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance)
		Util.Spawn(Binding.new, Instance)
	end)
end

--[=[
	@within Binding
	@function Get
	@param Instance Instance -- The instance to get the binding from.
	@return ServerBinding|ClientBinding -- The binding attached to the instance.

	This function gets the binding attached to an instance. There can only be
	one binding per instance.
]=]
function Binding.Get(Instance)
	if Util.IsServer then
		return Server.get(Instance)
	else
		return Client.get(Instance)
	end
end

return Binding
