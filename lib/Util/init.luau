local RunService = game:GetService("RunService")

--[=[
	@class Util

	A collection of utilities for Tink.
]=]
--[=[
	@within Util
	@prop IsServer boolean

	Whether or not the current context is the server.
	This is just the result of `RunService:IsServer()`.
]=]
--[=[
	@within Util
	@function Make
	@param ClassName string -- An Instance class name.
	@param Props {[string]: any}? -- A table of properties to set on the instance.
	@param Children {Instance}? -- A table of children to set on the instance.
	@return Instance

	This is just a convenience wrapper around `Instance.new`.
]=]
--[=[
	@within Util
	@function Wrap
	@param Callback function -- The callback to wrap.
	@param ... any -- Any arguments to pass to the callback.
	@return function -- A function that will call the callback when called.

	This is a nice way to wrap methods into functions. It essentially just
	returns a function that calls the callback with any args.

	```lua
	local greet = Util.Wrap(print, "Hello")
	greet("World") -- prints Hello World

	local callback = Util.Wrap(Class.Method, self) -- you can wrap class methods too
	```
]=]
--[=[
	@within Util
	@function Symbol
	@param Name string -- The name of the symbol.
	@return userdata

	This just returns a userdata which prints as "Symbol Name".
]=]
--[=[
	@within Util
	@function Spawn
	@param Callback function -- The callback to spawn.
	@param ... any -- Any arguments to pass to the callback.

	This is a wrapper around task.spawn that uses thread reuse
	to improve performance.
]=]
--[=[
	@within Util
	@prop Emitter Emitter
]=]
--[=[
	@within Util
	@prop Signal Signal
]=]

return {
	Emitter = require(script.Emitter),
	Signal = require(script.Signal),

	Make = require(script.Make),
	Wrap = require(script.Wrap),
	Symbol = require(script.Symbol),
	Spawn = require(script.Spawn),

	IsServer = RunService:IsServer(),
}