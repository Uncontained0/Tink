local Network = require(script.Network)
local Util = require(script.Util)
local Service = require(script.Service)
local Binding = require(script.Binding)

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