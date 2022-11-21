local RunService = game:GetService("RunService")

return {
	Emitter = require(script.Emitter),
	Signal = require(script.Signal),

	Make = require(script.Make),
	Wrap = require(script.Wrap),
	Symbol = require(script.Symbol),
	Spawn = require(script.Spawn),

	IsServer = RunService:IsServer(),
}