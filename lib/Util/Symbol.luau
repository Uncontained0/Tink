return function(Name: string)
	local Symbol = newproxy(true)

	getmetatable(Symbol).__tostring = function()
		return Name
	end

	return Symbol
end
