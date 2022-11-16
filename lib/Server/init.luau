local Event = require(script.Event)
local Function = require(script.Function)
local Value = require(script.Value)

local Net = {}

Net.Event = newproxy()
Net.Value = newproxy()

function Net.new(Parent, Name)
	local self = setmetatable({}, Net)

	Net.constructor(self, Parent, Name)

	return self
end

function Net:__newindex(index, value)
	if self._folder.Parent ~= self._parent then
		self._folder.Parent = self._parent
	end

	local setvalue

	if type(value) == "function" then
		setvalue = Function.new(self._instance, index)
		setvalue:setCallback(value)
	elseif typeof(value) == "userdata" then
		if value == Net.Event then
			setvalue = Event.new(self._instance, index)
		elseif value == Net.Value then
			setvalue = Value.new(self._instance, index)
		end
	else
		if self._values[index] then
			self._values[index]:set(value)
		else
			self._values[index] = Value.new(self._instance, index)
			self._values[index]:set(value)
		end

		setvalue = value
	end

	rawset(self, index, setvalue)
end

function Net:constructor(Parent, Name)
	self._folder = Instance.new("Folder")
	self._folder.Name = Name
	self._parent = Parent

	self._values = {}
end

return Net