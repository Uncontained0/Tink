local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Util = require(script.Parent.Parent.Util)
local Promise = require(script.Parent.Parent.Parent.Promise)

--[=[
	@class Serdes
	Serdes is used to serialize and deserialize data.
	Generally this turns identifier strings into smaller
	strings that can be sent over the network.
]=]

local Serdes = {
	NextId = 0,

	NameToId = {},
	IdToName = {},
	WaitingForId = {},

	Instance = ReplicatedStorage:WaitForChild("Tink"):WaitForChild("Serdes"),
}

--[=[
	@within Serdes
	@function RegisterIdentifier
	@param Name string -- The name of the identifier
	@return string -- The identifier string that can be sent over the network
	@server
	Registers an identifier with the Serdes system.
	This can only be done on the server, and it replicates
	to the client.
]=]
function Serdes.RegisterIdentifier(Name: string)
	assert(Util.IsServer, "RegisterIdentifier can only be called on the server")

	Serdes.NextId += 1

	local Id = string.pack("H", Serdes.NextId)

	Serdes.NameToId[Name] = Id
	Serdes.IdToName[Id] = Name

	Serdes.Instance:SetAttribute(Name, Id)

	return Id
end

--[=[
	@within Serdes
	@function GetIdentifier
	@param Name string -- The name of the identifier
	@return Promise<string> -- The identifier string that can be sent over the network
	
	Gets an identifier from the Serdes system. The promise won't resolve until
	the identifier is registered on the server.
]=]
function Serdes.GetIdentifier(Name: string)
	if Serdes.NameToId[Name] then
		return Promise.resolve(Serdes.NameToId[Name])
	elseif Serdes.WaitingForId[Name] then
		return Serdes.WaitingForId[Name]
	else
		Serdes.WaitingForId[Name] = Promise.new(function(resolve)
			local Connection
			Connection = Serdes.Instance:GetAttributeChangedSignal(Name):Connect(function()
				Connection:Disconnect()
				resolve(Serdes.Instance:GetAttribute(Name))
			end)
		end)

		return Serdes.WaitingForId[Name]
	end
end

--[=[
	@within Serdes
	@function Identifier
	@param Name string -- The name of the identifier
	@return Promise<string> -- The identifier string that can be sent over the network
	Gets an identifier from the Serdes system.
	If this is called on the server, it will register the identifier
	if it doesn't exist. If this is called on the client, it will
	wait for the identifier to be registered.

	This returns a promise that resolves with the identifier string.
]=]
function Serdes.Identifier(Name: string)
	if Util.IsServer then
		if not Serdes.NameToId[Name] then
			Serdes.RegisterIdentifier(Name)
		end

		return Serdes.GetIdentifier(Name)
	else
		return Serdes.GetIdentifier(Name)
	end
end

function Serdes.Listen()
	assert(not Util.IsServer, "Listen can only be called on the client")

	Serdes.Instance.AttributeChanged:Connect(function(Name)
		local Value = Serdes.Instance:GetAttribute(Name)

		Serdes.NameToId[Name] = Value
		Serdes.IdToName[Value] = Name
	end)

	for Name, Value in pairs(Serdes.Instance:GetAttributes()) do
		Serdes.NameToId[Name] = Value
		Serdes.IdToName[Value] = Name
	end
end

--[=[
	@within Serdes
	@function Name
	@param Id string -- The identifier string
	@return string -- The name of the identifier
]=]
function Serdes.Name(Id: string)
	return Serdes.IdToName[Id]
end

--[=[
	@within Serdes
	@function UUID
	@return string -- A UUID string
	This generates an HTTPService UUID, without the dashes.
]=]
function Serdes.UUID()
	return HttpService:GenerateGUID(false):gsub("-", "")
end

--[=[
	@within Serdes
	@function PackUUID
	@param UUID string -- The UUID string
	@return string -- The packed UUID string
	This packs a UUID string into a smaller string.
]=]
function Serdes.PackUUID(UUID)
	return string.gsub(UUID, ".", function(c)
		return string.format("%02X", string.byte(c))
	end)
end

--[=[
	@within Serdes
	@function UnpackUUID
	@param UUID string -- The packed UUID string
	@return string -- The UUID string
	This unpacks a packed UUID string into a larger string.
]=]
function Serdes.UnpackUUID(UUID)
	return string.gsub(UUID, "..", function(c)
		return string.char(tonumber(c, 16) :: number)
	end) :: string
end

return Serdes
