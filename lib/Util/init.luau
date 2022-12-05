local RunService = game:GetService("RunService")

local Emitter = require(script.Emitter)
local Signal = require(script.Signal)
local Promise = require(script.Promise)

export type Emitter = Emitter.Emitter
export type Signal = Signal.Signal
export type Promise = Promise.Promise

return {
	Emitter = Emitter,
	Signal = Signal,
	Promise = Promise,

	Make = require(script.Make),
	Wrap = require(script.Wrap),
	Symbol = require(script.Symbol),
	Spawn = require(script.Spawn),

	IsServer = RunService:IsServer(),
}