local Network = require(script.Network)
local Util = require(script.Util)
local Service = require(script.Service)
local Binding = require(script.Binding)

--[=[
	@class Tink
	The root of the Tink library.
]=]

return {
	--[=[
		@prop Network Network
		@within Tink
		A reference to the network class.
	]=]
	Network = Network,

	--[=[
		@prop Serdes Serdes
		@within Tink
	]=]
	Serdes = Network.Serdes,

	--[=[
		@prop Util Util
		@within Tink
	]=]
	Util = Util,

	--[=[
		@prop Service Service
		@within Tink
	]=]
	Service = Service,

	--[=[
		@function CreateService
		@within Tink
	]=]
	CreateService = Service.Create,

	--[=[
		@function GetService
		@within Tink
	]=]
	GetService = Service.Get,

	--[=[
		@prop Binding Binding
		@within Tink
	]=]
	Binding = Binding,
	
	--[=[
		@function CreateBinding
		@within Tink
	]=]
	CreateBinding = Binding.Create,

	--[=[
		@function Bind
		@within Tink
	]=]
	Bind = Binding.Bind,
}