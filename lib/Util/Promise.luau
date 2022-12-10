local Spawn = require(script.Parent.Spawn)

local Promise = {}
Promise.__index = Promise

function Promise.Promise(Callback: (Resolve: (...any) -> (), Reject: (Error: string) -> ()) -> ())
	local self = setmetatable({}, Promise)

	self.Status = "Pending"
	self.ResolveCallbacks = {} :: { (...any) -> () | thread }
	self.RejectCallbacks = {} :: { (Error: string) -> () | thread }

	self.Value = nil :: { any }?

	self.Thread = nil :: thread?
	self.Thread = coroutine.create(function()
		xpcall(Callback, function(Error)
			(self :: any):_Reject(Error)
		end, function(...)
			(self :: any):_Resolve(...)
		end, function(Error: string)
			(self :: any):_Reject(Error)
		end)
	end)

	task.spawn(self.Thread :: thread)

	return self
end

Promise.new = Promise.Promise :: (Callback: (Resolve: (...any) -> (), Reject: (Error: string) -> ()) -> ()) -> Promise

function Promise.Resolve(...): Promise
	local self = setmetatable({}, Promise)

	self.Status = "Resolved"
	self.ResolveCallbacks = {} :: { (...any) -> () | thread }
	self.RejectCallbacks = {} :: { (Error: string) -> () | thread }
	self.Value = { ... } :: { any }?
	self.Thread = nil :: thread?

	return self
end

function Promise.Reject(...): Promise
	local self = setmetatable({}, Promise)

	self.Status = "Rejected"
	self.ResolveCallbacks = {} :: { (...any) -> () | thread }
	self.RejectCallbacks = {} :: { (Error: string) -> () | thread }
	self.Value = { ... } :: { any }?
	self.Thread = nil :: thread?

	return self
end

function Promise.Retry(
	Callback: (Resolve: (...any) -> (), Reject: (Error: string) -> ()) -> (),
	MaxRetries: number,
	Delay: number?
): Promise
	return Promise.Promise(function(Resolve, Reject)
		local Retries = 0

		while true do
			pcall(Callback, Resolve, function(Error)
				Retries += 1

				if Retries >= MaxRetries then
					Reject(Error)
				end
			end)

			if Delay then
				task.wait(Delay)
			end
		end
	end)
end

function Promise._Resolve(self: Promise, ...)
	assert(self.Status == "Pending", "Cannot resolve a promise that is not pending.")

	self.Status = "Resolved"
	self.Value = { ... }

	for _, Callback in self.ResolveCallbacks do
		Spawn(Callback, ...)
	end

	if self.Thread then
		task.cancel(self.Thread)
	end
end

function Promise._Reject(self: Promise, Error: string)
	assert(self.Status == "Pending", "Cannot reject a promise that is not pending.")

	self.Status = "Rejected"
	self.Value = { Error }

	for _, Callback in self.RejectCallbacks do
		Spawn(Callback, Error)
	end

	if self.Thread then
		task.cancel(self.Thread)
	end
end

function Promise.Then(self: Promise, ResolveCallback: (...any) -> ()?, RejectCallback: (Error: string) -> ()?)
	if self.Status == "Resolved" then
		return Promise.Resolve(
			if ResolveCallback then ResolveCallback(unpack(self.Value :: { any })) else unpack(self.Value :: { any })
		)
	elseif self.Status == "Rejected" then
		return Promise.Reject(
			if RejectCallback then RejectCallback(unpack(self.Value :: { any })) else unpack(self.Value :: { any })
		)
	else
		return Promise.Promise(function(Resolve, Reject)
			table.insert(self.ResolveCallbacks, function(...)
				if ResolveCallback then
					Resolve(ResolveCallback(...))
				else
					Resolve(...)
				end
			end)

			table.insert(self.RejectCallbacks, function(Error)
				if RejectCallback then
					Resolve(RejectCallback(Error))
				else
					Reject(Error)
				end
			end)
		end)
	end
end

function Promise.Catch(self: Promise, RejectCallback: (Error: string) -> ())
	return self:Then(nil, RejectCallback)
end

function Promise.Finally(self: Promise, FinallyCallback: () -> ())
	return self:Then(function(...)
		FinallyCallback()
		return ...
	end, function(Error)
		FinallyCallback()
		error(Error)
	end)
end

function Promise.Await(self: Promise): (...any)
	if self.Status == "Resolved" then
		return unpack(self.Value :: { any })
	elseif self.Status == "Rejected" then
		return error(unpack(self.Value :: { any }))
	else
		local Current = coroutine.running()

		table.insert(self.ResolveCallbacks, Current)
		table.insert(self.RejectCallbacks, Current)

		coroutine.yield()

		if self.Status == "Resolved" then
			return unpack(self.Value :: { any })
		else
			return error(unpack(self.Value :: { any }))
		end
	end
end

export type Promise = typeof(Promise.Promise(...))

return Promise
