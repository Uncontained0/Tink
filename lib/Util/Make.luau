return function(className: string, props: { [string]: any }?, children: { Instance }?): Instance
	local instance = Instance.new(className :: any)

	if props then
		for i, v in props do
			(instance :: any)[i] = v
		end
	end

	if children then
		for _, child in children do
			child.Parent = instance
		end
	end

	return instance
end
