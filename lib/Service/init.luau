local Util = require(script.Parent.Util)

local Client = require(script.Client)
local Server = require(script.Server)

local Service = {}
local Services = {} :: { [string]: Client.Client | Server.Server }

function Service.CreateService(Name: string): Server.Server
	assert(Util.IsServer, "Services can only be created on the server!")

	if Services[Name] then
		return Services[Name] :: Server.Server
	else
		Services[Name] = Server.new(Name)
		return Services[Name] :: Server.Server
	end
end

function Service.GetService(Name: string): Client.Client
	assert(not Util.IsServer, "Service.GetService can only be called on the client!")

	if Services[Name] then
		return Services[Name] :: Client.Client
	else
		Services[Name] = Client.new(Name)
		return Services[Name] :: Client.Client
	end
end

export type Server = Server.Server
export type Client = Client.Client

return Service
