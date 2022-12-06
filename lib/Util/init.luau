local RunService = game:GetService("RunService")

local Signal = require(script.Signal)
local Promise = require(script.Promise)

export type Signal = Signal.Signal
export type Promise = Promise.Promise

return {
	Signal = Signal,
	Promise = Promise,

	Make = require(script.Make),
	Wrap = require(script.Wrap),
	Spawn = require(script.Spawn),

	IsServer = RunService:IsServer(),
}