local Util = require(script.Parent.Util)

local Server = require(script.Server)
local Client = require(script.Client)

--[=[
	@class Service

	Services allow you to create singletons that can be accessed from both the client and the server.
]=]
local Service = {}
local ServiceList = {}

--[=[
	@within Service
	@function Create
	@server
	@param Name string
	@return ServerService

	Creates a new service with the given name. This service can be accessed from both the client and the server.
	Services can be created from the server only, at any time.

	:::danger
	Creating duplicate services will result in undefined behavior, but if you know what you're doing
	you can use this to your advantage.
	:::
]=]
function Service.Create(Name)
	assert(Util.IsServer, "Service.Create must be called on the server")
	assert(ServiceList[Name] == nil, ("Service %s already exists"):format(Name))

	ServiceList[Name] = true

	return Server.new(Name)
end

--[=[
	@within Service
	@function Get
	@client
	@param Name string
	@return ClientService
	@yields

	Gets a service with the given name. This will yield until the service exists.
	If this process takes longer than 5 seconds, it will throw a warning.
]=]
function Service.Get(Name)
	assert(not Util.IsServer, "Service.Get must be called on the client")

	return Client.get(Name)
end

return Service
