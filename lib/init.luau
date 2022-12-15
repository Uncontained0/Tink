local Util = require(script.Util)
local Net = require(script.Net)
local Service = require(script.Service)

export type ServerService = Service.Server
export type ClientService = Service.Client

export type Promise = Util.Promise
export type Signal = Util.Signal
export type Emitter = Util.Emitter
export type Binding = Util.Binding
export type Collection = Util.Collection
export type Document = Util.Collection

return {
	Util = Util,
	Net = Net,
	Service = Service,

	CreateService = Service.CreateService,
	GetService = Service.GetService,
	Bind = Util.Binding.Bind,

	Binding = Util.Binding,
	Emitter = Util.Emitter,
	Signal = Util.Signal,
	Collection = Util.Collection,
	Promise = Util.Promise,
}
