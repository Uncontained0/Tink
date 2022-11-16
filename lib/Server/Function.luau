local Function = {}
Function.__index = Function

function Function.new(Parent, Name)
	local self = setmetatable({}, Function)

	Function.constructor(self, Parent, Name)

	return self
end

function Function:constructor(Parent, Name)
	self._instance = Instance.new("RemoteFunction")
	self._instance.Name = Name
	self._instance.Parent = Parent

	function self._instance.OnServerInvoke(player, ...)
		return self._callback(player, ...)
	end
end

function Function:setCallback(Callback)
	self._instance.OnServerInvoke = Callback
end

function Function._callback()
	error("Function callback not set")
end

return Function