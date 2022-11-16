local RunService = game:GetService("RunService")

local Server = require(script.Server)
local Client = require(script.Client)

local Tink = {}

local ServicesFolder = if RunService:IsServer() then Instance.new("Folder") else script:WaitForChild("Services")
ServicesFolder.Name = "Services"
ServicesFolder.Parent = script

function Tink.CreateService(Name)
	local Service = {}
	Service.Client = Server.new(script, Name)
	return Service
end