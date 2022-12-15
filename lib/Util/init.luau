local RunService = game:GetService("RunService")

local Signal = require(script.Signal)
local Emitter = require(script.Emitter)
local Collection = require(script.Collection)
local Promise = require(script.Promise)
local Binding = require(script.Binding)

export type Signal = Signal.Signal
export type Emitter = Emitter.Emitter
export type Collection = Collection.Collection
export type Document = Collection.Document
export type Promise = Promise.Promise
export type Binding = Binding.Binding

return {
	Signal = Signal,
	Emitter = Emitter,
	Collection = Collection,
	Promise = Promise,
	Binding = Binding,

	Spawn = require(script.Spawn),

	Make = function(ClassName: string, Props: { [string]: any }?, Children: { Instance }?): Instance
		local Instance = Instance.new(ClassName :: any)

		if Props then
			for Key, Value in pairs(Props) do
				(Instance :: any)[Key] = Value
			end
		end

		if Children then
			for _, Child in ipairs(Children) do
				Child.Parent = Instance
			end
		end

		return Instance
	end,

	Wrap = function(Callback, ...)
		local args = {...}	

		return function(...)
			local newargs = table.clone(args)
			for i = 1, select("#", ...) do
				newargs[#newargs + 1] = select(i, ...)
			end

			return Callback(unpack(newargs))
		end
	end,

	RandomString = function(Length: number): string
		local String = ""

		for _ = 1, Length do
			String = String .. string.char(math.random(0, 255))
		end

		return String
	end,

	IsServer = RunService:IsServer(),
	IsStudio = RunService:IsStudio(),
}
