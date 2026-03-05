--!strict
local Janitor = require(script.Parent.Packages.Janitor)
local IASAdapter = require(script.Parent.IASAdapter)

--- @class BindingBuilder
local BindingBuilder = {}
BindingBuilder.__index = BindingBuilder

export type BindingBuilderImpl = typeof(setmetatable(
	{} :: {
		_instance: InputBinding,
		_janitor: any,
		_name: string,
		_destroyed: boolean,
		_actionBuilder: any,
		_contextBuilder: any,
	},
	BindingBuilder
))

function BindingBuilder.new(
	keyCode: Enum.KeyCode,
	actionBuilder: any,
	contextBuilder: any,
	parentJanitor: any
): BindingBuilderImpl
	local janitor = parentJanitor:Add(Janitor.new(), "Destroy")
	local instance = janitor:Add(IASAdapter.newBinding(keyCode))

	local self = setmetatable({
		_instance = instance,
		_janitor = janitor,
		_name = keyCode.Name,
		_destroyed = false,
		_actionBuilder = actionBuilder,
		_contextBuilder = contextBuilder,
	}, BindingBuilder)

	return self
end

--- Sets the primary modifier key for this binding.
--- @param modifier Enum.KeyCode
--- @return BindingBuilder
function BindingBuilder.withModifier(self: BindingBuilderImpl, modifier: Enum.KeyCode): BindingBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	self._instance.PrimaryModifier = modifier
	return self
end

--- Sets the secondary modifier key for this binding.
--- @param modifier Enum.KeyCode
--- @return BindingBuilder
function BindingBuilder.withSecondaryModifier(self: BindingBuilderImpl, modifier: Enum.KeyCode): BindingBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	self._instance.SecondaryModifier = modifier
	return self
end

--- Returns this binding's owning action builder.
--- @return ActionBuilder
function BindingBuilder.action(self: BindingBuilderImpl): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	return self._actionBuilder
end

--- Returns this binding's owning context builder.
--- @return ContextBuilder
function BindingBuilder.context(self: BindingBuilderImpl): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	return self._contextBuilder
end

--- Destroys this binding and its managed resources.
function BindingBuilder.destroy(self: BindingBuilderImpl)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._janitor:Destroy()
end

--- Returns the underlying InputBinding instance.
--- @return InputBinding
function BindingBuilder.getRawInstance(self: BindingBuilderImpl): InputBinding
	if self._destroyed then
		error("[EZInput] Cannot use destroyed binding '" .. self._name .. "'", 2)
	end
	return self._instance
end

return BindingBuilder
