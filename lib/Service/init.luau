local Util = require(script.Parent.Util)

local Server = require(script.Server)
local Client = require(script.Client)

local Service = {}
local ServiceList = {}

function Service.Create(Name)
	assert(Util.IsServer, "Service.Create must be called on the server")
	assert(ServiceList[Name] == nil, ("Service %s already exists"):format(Name))

	ServiceList[Name] = true

	return Server.new(Name)
end

function Service.Get(Name)
	assert(not Util.IsServer, "Service.Get must be called on the client")

	return Client.get(Name)
end

return Service
