local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)
local Spawn = require(script.Parent.Spawn)

local DataStore = {}
DataStore.__index = DataStore

type Entry = {
	Data: { [string]: any },
	Session: {
		Server: string,
		LastUpdated: number,
	} | nil,
}

local MAX_RETRIES = 5
local SESSION_TIMEOUT = 600

local Store = (
	if RunService:IsStudio()
		then DataStoreService:GetDataStore("Testing")
		else DataStoreService:GetDataStore("Production")
) :: DataStore

function DataStore.new(Key, Template)
	local self = setmetatable({}, DataStore)

	DataStore.constructor(self, Key)

	return self
end

function DataStore:constructor(Key, Template)
	self.Key = Key
	self.Template = Template

	self.Saved = Signal.new()
	self.
self:Load()
end

function DataStore:Load()
	self.Loader = Promise.Retry(function(Resolve)
		local EntryLocal, UserIds

		Store:UpdateAsync(self.Key, function(Entry: Entry, Metadata: DataStoreKeyInfo)
			if Entry == nil then
				Entry = {
					Data = {},
					Session = nil,
				}
			end

			Entry.Session = {
				Server = game.JobId,
				LastUpdated = os.time(),
			}

			EntryLocal = Entry
			UserIds = Metadata:GetUserIds()

			return Entry, Metadata:GetUserIds()
		end)

		Resolve(EntryLocal, UserIds)
	end, MAX_RETRIES)
		:Then(function(Entry: Entry, UserIds)
			self.DoSave = true
			self.Data = Entry.Data
			self.UserIds = UserIds

			self:Reconcile()
			self:StartAutoSave()
		end, function()
			self.DoSave = false
			self.Data = table.clone(self.Template)
			self.UserIds = {}
		end)
		:Finally(function()
			self.Loader = nil
		end)
end

function DataStore:WaitForLoad()
	if self.Loader then
		self.Loader:Await()
	end
end

function DataStore:Reconcile()
	for Key, Value in pairs(self.Template) do
		if self.Data[Key] == nil then
			self.Data[Key] = Value
		end
	end
end

function DataStore:Save(ClearSession: boolean?)
	if self.DoSave then
		if self.Saver then
			return self.Saver
		end

		self.Saver = Promise.Retry(function(Resolve)
			Store:UpdateAsync(self.Key, function(Entry: Entry, Metadata: DataStoreKeyInfo)
				if Entry == nil then
					Entry = {
						Data = {},
						Session = nil,
					}
				end

				if Entry.Session == nil then
					Entry.Session = {
						Server = game.JobId,
						LastUpdated = os.time(),
					}
				end

				if Entry.Session and Entry.Session.Server == game.JobId then
					Entry.Data = self.Data
					Entry.Session.LastUpdated = os.time()

					if ClearSession then
						Entry.Session = nil
					end

					return Entry, self.UserIds
				elseif Entry.Session and os.time() - Entry.Session.LastUpdated > SESSION_TIMEOUT then
					Entry.Session = {
						Server = game.JobId,
						LastUpdated = os.time(),
					}

					Entry.Data = self.Data

					if ClearSession then
						Entry.Session = nil
					end

					return Entry, self.UserIds
				else
					return Entry, Metadata:GetUserIds()
				end
			end)
		end, MAX_RETRIES):Finally(function()
			self.Saver = nil
		end)

		return self.Saver
	end

	return Promise.Resolve()
end

return DataStore
