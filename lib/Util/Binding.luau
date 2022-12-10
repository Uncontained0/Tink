local CollectionService = game:GetService("CollectionService")

local Binding = {}
Binding.__index = Binding

function Binding.Binding(Instance: Instance)
	local self = setmetatable({}, Binding)

	self.Instance = Instance

	return self
end

Binding.new = Binding.Binding :: (Instance) -> Binding

function Binding.Check(Instance: Instance): boolean
	return true
end

function Binding.Start(self: Binding) end
function Binding.Stop(self: Binding) end

function Binding.Bind(Binding: Binding, Tag: string)
	local Bindings = {} :: { [Instance]: Binding }

	CollectionService:GetInstanceAddedSignal(Tag):Connect(function(Instance)
		if Binding.Check(Instance) then
			local BindingInstance = Binding.new(Instance)
			BindingInstance:Start()
		end
	end)

	CollectionService:GetInstanceRemovedSignal(Tag):Connect(function(Instance)
		if Bindings[Instance] then
			Bindings[Instance]:Stop()
			Bindings[Instance] = nil
		end
	end)

	for _, Instance in ipairs(CollectionService:GetTagged(Tag)) do
		if Binding.Check(Instance) then
			local BindingInstance = Binding.new(Instance)

			BindingInstance:Start()
			Bindings[Instance] = BindingInstance
		end
	end
end

export type Binding = typeof(Binding.Binding(...))

return Binding
