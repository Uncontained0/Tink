local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)

local Store: GlobalDataStore
if RunService:IsStudio() then
	Store = DataStoreService:GetDataStore("TestingDataStore")
else
	Store = DataStoreService:GetDataStore("ProductionDataStore")
end

local MAX_RETRIES = 5
local SAVE_DELAY = 300
local LOCK_TIMEOUT = 900

local DataStore = {}
DataStore.__index = DataStore

function DataStore.new(Key: string, Template: { [string]: any })
	local self = setmetatable({}, DataStore)

	self.Key = Key
	self.Template = Template

	self.AutosaveStart = Signal.new() :: Signal.Signal
	self.AutosaveEnd = Signal.new() :: Signal.Signal

	self.Data = nil :: { [string]: any }?
	self.UserIds = {} :: { number }

	self.Loaded = false
	self.DoSave = false

	self.Loading = nil :: Promise.Promise?
	self.Saving = nil :: Promise.Promise?

	self.AutosaveThread = nil :: thread?
	
	self:Load()

	return self
end

function DataStore:Load()
	if self.Loading ~= nil or self.Data ~= nil then
		return
	end

	self.Loading = Promise.Retry(function(Resolve)
		local OutData, UserIds

		Store:UpdateAsync(self.Key, function(Data, KeyInfo: DataStoreKeyInfo)
			if Data == nil then
				Data = {
					Data = {},
					Session = nil,
				}
			end

			Data.Session = {
				Owner = game.JobId,
				LastLocked = os.time(),
			}

			OutData = Data.Data
			UserIds = KeyInfo:GetUserIds()

			return Data, KeyInfo:GetUserIds()
		end)

		Resolve(OutData, UserIds)
	end, MAX_RETRIES):Then(function(Data: { [string]: any }, UserIds: { number })
		self.Data = Data
		self.UserIds = UserIds

		self.DoSave = true
	end, function()
		self.Data = table.clone(self.Template)
		self.UserIds = {}
	end):Finally(function()
		self.Loading = nil
		self.Loaded = true
	end)
end

function DataStore:Save(RemoveLock: boolean?)
	if self.Saving ~= nil or not self.DoSave then
		return self.Saving or Promise.Resolve()
	end

	self.Saving = Promise.Retry(function(Resolve)
		Store:UpdateAsync(self.Key, function(Data)
			if Data == nil then
				Data = {
					Data = {},
					Session = nil,
				}
			end

			if Data.Session == nil then
				if not RemoveLock then
					Data.Session = {
						Owner = game.JobId,
						LastLocked = os.time(),
					}
				end

				Data.Data = self.Data
			elseif Data.Session.Owner == game.JobId then
				Data.Data = self.Data

				if RemoveLock then
					Data.Session = nil
				else
					Data.Session.LastLocked = os.time()
				end
			elseif os.time() - Data.Session.LastLocked > LOCK_TIMEOUT then
				if not RemoveLock then
					Data.Session = {
						Owner = game.JobId,
						LastLocked = os.time(),
					}
				end

				Data.Data = self.Data
			end

			return Data, self.UserIds
		end)
	end, MAX_RETRIES):Finally(function()
		self.Saving = nil :: any
	end)

	return self.Saving
end

function DataStore:StartAutosave()
	self.AutosaveThread = task.spawn(function()
		while self.DoSave do
			task.wait(SAVE_DELAY)
			self.AutosaveStart:Fire()

			self:Save():Finally(function()
				self.AutosaveEnd:Fire()
			end)
		end
	end)
end

function DataStore:StopAutosave()
	self.AutosaveThread = self.AutosaveThread :: thread?

	if self.AutosaveThread ~= nil then
		task.cancel(self.AutosaveThread)
		self.AutosaveThread = nil
	end
end

function DataStore:Release()
	self:StopAutosave()
	self:Save(true)
end

return DataStore
