local DataStoreService = game:GetService("DataStoreService")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)

local MAX_RETRIES = 3
local RETRY_DELAY = 10
local SAVE_DELAY = 300
local LOCK_TIMEOUT = 900

local Document = {}
Document.__index = Document

function Document.Document(Collection: Collection, Key: string)
	local self = setmetatable({}, Document)

	self.Key = Key

	self.Template = Collection.Template
	self.DataStore = Collection.DataStore

	self._Loading = false
	self._Saving = nil :: Promise.Promise?

	self.DoSave = false
	self.Released = false

	self.Data = {} :: { [string]: any }
	self.UserIds = {} :: { number }

	self.AutosaveThread = nil :: thread?
	self.AutosaveStart = Signal.new()
	self.AutosaveEnd = Signal.new()

	return self
end

Document.new = Document.Document :: (Collection: Collection, Key: string) -> Document

function Document.Load(self: Document)
	assert(self._Loading, "Document is already loading or loaded.")
	self._Loading = true

	return Promise.Retry(function(Resolve)
		local ReturnData, UserIds

		self.DataStore:UpdateAsync(self.Key, function(Value, KeyInfo: DataStoreKeyInfo)
			if Value == nil then
				Value = {
					Data = {},
					Lock = nil :: { Owner: number, Time: number }?,
				}
			end

			Value.Lock = {
				Owner = game.JobId,
				Time = os.time(),
			}

			ReturnData = Value.Data
			UserIds = KeyInfo:GetUserIds()

			return Value, KeyInfo:GetUserIds()
		end)

		Resolve(ReturnData, UserIds)
	end, MAX_RETRIES, RETRY_DELAY):Then(function(ReturnData, UserIds)
		self.Data = ReturnData
		self.UserIds = UserIds

		for i, v in self.Template do
			if self.Data[i] == nil then
				self.Data[i] = v
			end
		end

		self.DoSave = true

		return true
	end, function(Error)
		self.Data = table.clone(self.Template)

		return false, Error
	end)
end

function Document.Save(self: Document, Force: boolean?, RemoveLock: boolean?): Promise.Promise
	assert(not self.Released, "Cannot save a released document.")

	if not self.DoSave then
		return Promise.Resolve()
	end

	if self._Saving then
		return self._Saving
	end

	self._Saving = Promise.Retry(function(Resolve, Reject)
		self.DataStore:UpdateAsync(self.Key, function(Value)
			if Value == nil then
				Value = {
					Data = {},
					Lock = nil :: { Owner: number, Time: number }?,
				}
			end

			if Value.Lock == nil then
				if not RemoveLock then
					Value.Lock = {
						Owner = game.JobId,
						Time = os.time(),
					}
				end

				Value.Data = self.Data
			elseif Value.Lock.Owner == game.JobId then
				if not RemoveLock then
					Value.Lock = {
						Owner = game.JobId,
						Time = os.time(),
					}
				end

				Value.Data = self.Data
			elseif os.time() - Value.Lock.Time > LOCK_TIMEOUT then
				if not RemoveLock then
					Value.Lock = {
						Owner = game.JobId,
						Time = os.time(),
					}
				end

				Value.Data = self.Data
			elseif Force then
				if not RemoveLock then
					Value.Lock = {
						Owner = game.JobId,
						Time = os.time(),
					}
				end

				Value.Data = self.Data
			end

			return Value, self.UserIds
		end)
	end, MAX_RETRIES, RETRY_DELAY):Finally(function()
		self._Saving = nil :: any
	end)

	return self._Saving :: Promise.Promise
end

function Document.Release(self: Document, Force: boolean?)
	return Promise.new(function(Resolve)
		if self._Saving then
			self._Saving:Await()
		end

		self:Save(Force, true :: boolean?):Then(function()
			self.Released = true
			Resolve()
		end, function(Error)
			warn("Failed to release document: " .. Error)
		end)
	end)
end

function Document.AddUserId(self: Document, UserId: number)
	if not table.find(self.UserIds, UserId) then
		table.insert(self.UserIds, UserId)
	end
end

function Document.RemoveUserId(self: Document, UserId: number)
	local Index = table.find(self.UserIds, UserId)

	if Index then
		table.remove(self.UserIds, Index)
	end
end

function Document.HasUserId(self: Document, UserId: number)
	return table.find(self.UserIds, UserId) ~= nil
end

function Document.StartAutosave(self: Document)
	assert(self.AutosaveThread == nil, "Autosave thread already running.")

	self.AutosaveThread = task.spawn(function()
		while not self.Released do
			task.wait(SAVE_DELAY)

			self.AutosaveStart:Fire()
			self:Save():Await()
			self.AutosaveEnd:Fire()
		end
	end)
end

export type Document = typeof(Document.Document(table.unpack(...)))

local Collection = {}
Collection.__index = Collection

local Collections = {} :: { [string]: Collection }

function Collection.Collection(Name: string, Template: { [string]: any })
	if Collections[Name] then
		return Collections[Name] :: Collection
	end

	local self = setmetatable({}, Collection)

	self.Name = Name
	self.Template = Template

	self.DataStore = DataStoreService:GetDataStore(Name) :: DataStore
	self.Documents = {} :: { [string]: Promise.Promise }

	Collections[Name] = self

	return self
end

Collection.new = Collection.Collection :: (Name: string, Template: { [string]: any }) -> Collection

function Collection.Document(self: Collection, Key: string)
	if not self.Documents[Key] then
		local Doc = Document.Document(self, Key)

		self.Documents[Key] = Doc:Load():Then(function(Loaded, Error)
			if not Loaded then
				warn("Failed to load document: " .. Error)
			else
				Doc:StartAutosave()
			end

			return Doc
		end)
	end

	return self.Documents[Key]
end

Collection.Doc = Collection.Document

function Collection.ReleaseAll(self: Collection)
	for _, v in self.Documents do
		v:Then(function(Doc)
			Doc:Release()
		end)
	end
end

export type Collection = typeof(Collection.Collection(table.unpack(...)))

return Collection
