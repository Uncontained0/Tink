local Network = require(script.Network)
local Util = require(script.Util)
local Service = require(script.Service)
local Binding = require(script.Binding)

--[=[
	@class Tink

	The root of the Tink library.
]=]

--[=[
	@prop Network Network
	@within Tink

	A reference to the [Network] class.
]=]

--[=[
	@prop Serdes Serdes
	@within Tink

	A reference to the [Serdes] class.
]=]

--[=[
	@prop Util Util
	@within Tink

	A reference to the [Util] class.
]=]

--[=[
	@prop Service Service
	@within Tink

	A reference to the [Service] class.
]=]

--[=[
	@function CreateService
	@within Tink
	@param Name string
	@return ServerService
	@server

	A reference to [Service.Create].
]=]

--[=[
	@function GetService
	@within Tink
	@param Name string
	@return ClientService
	@client

	A reference to [Service.Get].

]=]

--[=[
	@prop Binding Binding
	@within Tink

	A reference to the [Binding] class.
]=]

--[=[
	@function CreateBinding
	@within Tink
	@return ServerBinding|ClientBinding

	A reference to [Binding.Create].
]=]

--[=[
	@function Bind
	@within Tink
	@param Tag string
	@param Binding ServerBinding|ClientBinding
	
	A reference to [Binding.Bind].
]=]

return {
	Network = Network,
	Serdes = Network.Serdes,

	Util = Util,

	Service = Service,
	CreateService = Service.Create,
	GetService = Service.Get,

	Binding = Binding,
	CreateBinding = Binding.Create,
	Bind = Binding.Bind,
}