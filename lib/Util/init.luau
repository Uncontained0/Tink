local RunService = game:GetService("RunService")

local Signal = require(script.Signal)
local Emitter = require(script.Emitter)
local Collection = require(script.Collection)
local Promise = require(script.Promise)

export type Signal = Signal.Signal
export type SignalConnection = Signal.Connection
export type Emitter = Emitter.Emitter
export type EmitterConnection = Emitter.Connection
export type Collection = Collection.Collection
export type Promise = Promise.Promise

return {
	Signal = Signal,
	Emitter = Emitter,
	Collection = Collection,
	Promise = Promise,

	Make = require(script.Make),
	Wrap = require(script.Wrap),
	Spawn = require(script.Spawn),

	IsServer = RunService:IsServer(),
}