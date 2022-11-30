local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)

local DataStore = {}
DataStore.__index = DataStore

DataStore.Store = if RunService:IsStudio() then
	DataStoreService:GetDataStore("Testing")
else
	DataStoreService:GetDataStore("Production")

function DataStore.new(Key)
	local self = setmetatable({}, DataStore)

	DataStore.constructor(self, Key)

	return self
end

function DataStore:constructor(Key)
	self.Key = Key
	

end
