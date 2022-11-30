local Promise = {}
Promise.__index = Promise

function Promise.new(Callback)
	local self = setmetatable({}, Promise)

	Promise.constructor(self, Callback)

	return self
end

function Promise.Resolve(...)
	local self = setmetatable({}, Promise)

	self.Status = "Resolved"
	self.Value = { ... }

	return self
end

function Promise.Reject(...)
	local self = setmetatable({}, Promise)

	self.Status = "Rejected"
	self.Value = { ... }

	return self
end

function Promise:constructor(Callback: (Resolve: (...any) -> (), Reject: (Error: string) -> ()) -> ())
	self.Status = "Pending"
	self.ResolveCallbacks = {}
	self.RejectCallbacks = {}

	self.Thread = coroutine.create(function()
		xpcall(Callback, function(Error)
			self:_Reject(Error)
		end, function(...)
			self:_Resolve(...)
		end, function(Error)
			self:_Reject(Error)
		end)
	end)

	task.spawn(self.Thread)

	return self
end

function Promise:_Resolve(...)
	assert(self.Status == "Pending", "Cannot resolve a promise that is not pending.")

	self.Status = "Resolved"
	self.Value = { ... }

	for _, Callback in self.ResolveCallbacks do
		Callback(...)
	end

	task.cancel(self.Thread)
end

function Promise:_Reject(Error)
	assert(self.Status == "Pending", "Cannot reject a promise that is not pending.")

	self.Status = "Rejected"
	self.Value = { Error }

	for _, Callback in self.RejectCallbacks do
		Callback(Error)
	end

	task.cancel(self.Thread)
end

function Promise:Then(ResolveCallback: (...any) -> ()?, RejectCallback: (Error: any) -> ()?)
	if self.Status == "Resolved" then
		return Promise.Resolve(if ResolveCallback then ResolveCallback(unpack(self.Value)) else unpack(self.Value))
	elseif self.Status == "Rejected" then
		return Promise.Reject(if RejectCallback then RejectCallback(unpack(self.Value)) else unpack(self.Value))
	else
		return Promise.new(function(Resolve, Reject)
			table.insert(self.ResolveCallbacks, function(...)
				if ResolveCallback then
					Resolve(ResolveCallback(...))
				else
					Resolve(...)
				end
			end)

			table.insert(self.RejectCallbacks, function(Error)
				if RejectCallback then
					Reject(RejectCallback(Error))
				else
					Reject(Error)
				end
			end)
		end)
	end
end

function Promise:Catch(RejectCallback: (Error: any) -> ())
	return self:Then(nil, RejectCallback)
end

function Promise:Finally(FinallyCallback: () -> ())
	return self:Then(function(...)
		FinallyCallback()
		return ...
	end, function(Error)
		FinallyCallback()
		error(Error)
	end)
end

function Promise:Await()
	if self.Status == "Resolved" then
		return unpack(self.Value)
	elseif self.Status == "Rejected" then
		return error(unpack(self.Value))
	else
		local Current = coroutine.running()

		table.insert(self.ResolveCallbacks, Current)
		table.insert(self.RejectCallbacks, Current)

		coroutine.yield()

		if self.Status == "Resolved" then
			return unpack(self.Value)
		else
			return error(unpack(self.Value))
		end
	end
end

return Promise
