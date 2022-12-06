local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)

local MAX_RETRIES = 5
local SAVE_DELAY = 300
local LOCK_TIMEOUT = 900

local Document = {}
Document.__index = Document

function Document.new(Collection: Collection, Key: string)
	local self = setmetatable({}, Document)

	self.Key = Key

	-- For some reason I have to specify these types
	self.Template = Collection.Template
	self.DataStore = Collection.DataStore

	self._Loading = false
	self._Saving = nil :: Promise.Promise?

	self.DoSave = false

	self.Data = {} :: { [string]: any }
	self.UserIds = {} :: { number }

	return self
end

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
	end, MAX_RETRIES):Then(function(ReturnData, UserIds)
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

function Document.Save(self: Document, Options: { Force: boolean?, RemoveLock: boolean? }?): Promise.Promise
	if not self.DoSave then
		return Promise.Resolve()
	end

	if self._Saving then
		return self._Saving
	end

	local Opts: { Force: boolean?, RemoveLock: boolean? } = Options or {}

	self._Saving = Promise.Retry(function(Resolve, Reject)
		self.DataStore:UpdateAsync(self.Key, function(Value)
			if Value == nil then
				Value = {
					Data = {},
					Lock = nil :: { Owner: number, Time: number }?,
				}
			end

			if Value.Lock == nil then
				if not Opts.RemoveLock then
					Value.Lock = {
						Owner = game.JobId,
						Time = os.time(),
					}
				end
			elseif Value.Lock.Owner ~= game.JobId and (os.time() - Value.Lock.Time > LOCK_TIMEOUT or Opts.Force) then
				Value.Lock = {
					Owner = game.JobId,
					Time = os.time(),
				}
			end

			return Value, self.UserIds
		end)
	end, MAX_RETRIES):Finally(function()
		self._Saving = nil :: any
	end)

	return self._Saving
end

local Collection = {}
Collection.__index = Collection

function Collection.new(Name: string, Template: { [string]: any })
	local self = setmetatable({}, Collection)

	self.Name = Name
	self.Template = Template

	self.DataStore = DataStoreService:GetDataStore(Name) :: DataStore
	self.Documents = {} :: { [string]: Document }

	return self
end

export type Collection = typeof(Collection.new("Name", {}))
export type Document = typeof(Document.new(Collection.new("Name", {}), "Key"))

local c = Collection.new("Test", {
	Hello = "World",
})

local d: Document = Document.new(c, "Key")
