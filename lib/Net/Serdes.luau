local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Parent.Util)

local Serdes = {
	Instance = ReplicatedStorage:WaitForChild("TinkNet"),

	NameToId = {},
	IdToName = {},

	Next = 0,
}

function Serdes.RegisterIdentifier(Name: string)
	assert(Util.IsServer, "Cannot register identifiers on the client")

	local Identifier = string.pack("H", Serdes.Next)
	Serdes.Next += 1

	Serdes.NameToId[Name] = Identifier
	Serdes.IdToName[Identifier] = Name

	Serdes.Instance:SetAttribute(Name, Identifier)

	return Identifier
end

function Serdes.Listen()
	assert(not Util.IsServer, "Cannot listen on the server")

	Serdes.Instance.AttributeChanged:Connect(function(Name)
		local Identifier = Serdes.Instance:GetAttribute(Name)

		Serdes.NameToId[Name] = Identifier
		Serdes.IdToName[Identifier] = Name
	end)
end

function Serdes.Identifier(Name: string)
	if Util.IsServer then
		if Serdes.NameToId[Name] then
			return Util.Promise.Resolve(Serdes.NameToId[Name])
		else
			return Util.Promise.Resolve(Serdes.RegisterIdentifier(Name))
		end
	else
		if Serdes.NameToId[Name] then
			return Util.Promise.Resolve(Serdes.NameToId[Name])
		else
			return Util.Promise.new(function(Resolve)
				local Time = 0
				while true do
					if Time ~= nil then
						Time += task.wait()
					else
						task.wait()
					end

					if Time ~= nil and Time > 5 then
						warn(
							"It's taking a while to get identifier '" .. Name .. "'. Make sure it exists on the server."
						)
					end
				end
			end)
		end
	end
end

function Serdes.Name(Identifier: string)
	return Serdes.IdToName[Identifier]
end

return Serdes
