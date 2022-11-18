return function(callback, ...)
	local args = {...}	

	return function(...)
		local newargs = table.clone(args)
		for i = 1, select("#", ...) do
			newargs[#newargs + 1] = select(i, ...)
		end

		return callback(unpack(newargs))
	end
end
