return function(className, props, children)
	local instance = Instance.new(className)

	for i, v in props or {} do
		instance[i] = v
	end

	for i, v in children or {} do
		v.Parent = instance
	end

	return instance
end
