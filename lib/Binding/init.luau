local CollectionService = game:GetService("CollectionService")

local Util = require(script.Parent.Util)

local Server = require(script.Server)
local Client = require(script.Client)

local Binding = {}

function Binding.Create()
	if Util.IsServer then
		return setmetatable({}, Server)
	else
		return setmetatable({}, Client)
	end
end

function Binding.Bind(Tag, Binding)
	for _, v in CollectionService:GetTagged(Tag) do
		Util.Spawn(Binding.new, v)
	end

	CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance)
		Util.Spawn(Binding.new, Instance)
	end)
end

function Binding.Get(Instance)
	if Util.IsServer then
		return Server.get(Instance)
	else
		return Client.get(Instance)
	end
end

return Binding
