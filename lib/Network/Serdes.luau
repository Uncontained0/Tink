local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Util = require(script.Parent.Parent.Util)
local Promise = Util.Promise

local Serdes = {
	NextId = 0,

	NameToId = {},
	IdToName = {},
	WaitingForId = {},

	Instance = ReplicatedStorage:WaitForChild("Tink"):WaitForChild("Serdes"),
}

function Serdes.RegisterIdentifier(Name: string)
	assert(Util.IsServer, "RegisterIdentifier can only be called on the server")

	Serdes.NextId += 1

	local Id = string.pack("H", Serdes.NextId)

	Serdes.NameToId[Name] = Id
	Serdes.IdToName[Id] = Name

	Serdes.Instance:SetAttribute(Name, Id)

	return Id
end

function Serdes.GetIdentifier(Name: string)
	if Serdes.NameToId[Name] then
		return Promise.Resolve(Serdes.NameToId[Name])
	elseif Serdes.WaitingForId[Name] then
		return Serdes.WaitingForId[Name]
	else
		Serdes.WaitingForId[Name] = Promise.new(function(resolve)
			local Connection
			Connection = Serdes.Instance:GetAttributeChangedSignal(Name):Connect(function()
				Connection:Disconnect()
				resolve(Serdes.Instance:GetAttribute(Name))
			end)

			task.delay(5, function()
				if Connection.Connected then
					warn(("It is taking a long time to get identifier %s, are you sure it exists?"):format(Name))
				end
			end)
		end)

		return Serdes.WaitingForId[Name]
	end
end

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

function Serdes.Name(Id: string)
	return Serdes.IdToName[Id]
end

function Serdes.UUID()
	return HttpService:GenerateGUID(false):gsub("-", "")
end

function Serdes.PackUUID(UUID)
	return string.gsub(UUID, ".", function(c)
		return string.format("%02X", string.byte(c))
	end)
end

function Serdes.UnpackUUID(UUID)
	return string.gsub(UUID, "..", function(c)
		return string.char(tonumber(c, 16) :: number)
	end) :: string
end

return Serdes
