--!strict
local IASAdapter = require(script.Parent.IASAdapter)

local BindingBuilder = {}
BindingBuilder.__index = BindingBuilder

export type BindingBuilderImpl = typeof(setmetatable(
	{} :: {
		_instance: InputBinding,
		_trove: any, -- child Trove
		_name: string,
		_destroyed: boolean,
		_actionBuilder: any, -- ActionBuilder back-reference
		_contextBuilder: any, -- ContextBuilder back-reference
	},
	BindingBuilder
))

function BindingBuilder.new(
	keyCode: Enum.KeyCode,
	actionBuilder: any,
	contextBuilder: any,
	parentTrove: any
): BindingBuilderImpl
	-- Create a child trove so parent action destroy cascades
	local trove = parentTrove:Extend()
	local instance = trove:Add(IASAdapter.newBinding(keyCode))

	local self = setmetatable({
		_instance = instance,
		_trove = trove,
		_name = keyCode.Name,
		_destroyed = false,
		_actionBuilder = actionBuilder,
		_contextBuilder = contextBuilder,
	}, BindingBuilder)

	return self
end

function BindingBuilder.withModifier(self: BindingBuilderImpl, modifier: Enum.KeyCode): BindingBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	self._instance.PrimaryModifier = modifier
	return self
end

function BindingBuilder.withSecondaryModifier(self: BindingBuilderImpl, modifier: Enum.KeyCode): BindingBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	self._instance.SecondaryModifier = modifier
	return self
end

function BindingBuilder.action(self: BindingBuilderImpl): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	return self._actionBuilder
end

function BindingBuilder.context(self: BindingBuilderImpl): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	return self._contextBuilder
end

function BindingBuilder.destroy(self: BindingBuilderImpl)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._trove:Destroy()
end

function BindingBuilder.getRawInstance(self: BindingBuilderImpl): InputBinding
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	return self._instance
end

return BindingBuilder
