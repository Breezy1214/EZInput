--!strict
local IASAdapter = require(script.Parent.IASAdapter)

-- Lazy require to break circular dependency (ActionBuilder <-> BindingBuilder)
local BindingBuilder
local function getBindingBuilder()
	if not BindingBuilder then
		BindingBuilder = require(script.Parent.BindingBuilder)
	end
	return BindingBuilder
end

local ActionBuilder = {}
ActionBuilder.__index = ActionBuilder

export type ActionBuilderImpl = typeof(setmetatable(
	{} :: {
		_instance: InputAction,
		_trove: any, -- child Trove
		_name: string,
		_destroyed: boolean,
		_eventsWired: boolean,
		_contextBuilder: any, -- ContextBuilder back-reference
		_bindings: { [string]: any },
		_callbacks: {
			pressed: { (actionName: string) -> () },
			released: { (actionName: string) -> () },
			stateChanged: { (actionName: string, newState: boolean) -> () },
		},
	},
	ActionBuilder
))

function ActionBuilder.new(name: string, contextBuilder: any, parentTrove: any): ActionBuilderImpl
	-- Create a child trove so parent context destroy cascades
	local trove = parentTrove:Extend()
	local instance = trove:Add(IASAdapter.newAction(name, Enum.InputActionType.Bool))

	local self = setmetatable({
		_instance = instance,
		_trove = trove,
		_name = name,
		_destroyed = false,
		_eventsWired = false,
		_contextBuilder = contextBuilder,
		_bindings = {} :: { [string]: any },
		_callbacks = {
			pressed = {},
			released = {},
			stateChanged = {},
		},
	}, ActionBuilder)

	return self
end

function ActionBuilder._wireEvents(self: ActionBuilderImpl)
	if self._eventsWired then
		return
	end
	self._eventsWired = true

	self._trove:Add(self._instance.Pressed:Connect(function()
		for _, cb in self._callbacks.pressed do
			cb(self._name)
		end
		for _, cb in self._callbacks.stateChanged do
			cb(self._name, true)
		end
	end))

	self._trove:Add(self._instance.Released:Connect(function()
		for _, cb in self._callbacks.released do
			cb(self._name)
		end
		for _, cb in self._callbacks.stateChanged do
			cb(self._name, false)
		end
	end))
end

function ActionBuilder.bind(self: ActionBuilderImpl, keyCode: Enum.KeyCode): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	if self._bindings[keyCode.Name] then
		error("[EZInput] Duplicate binding '" .. keyCode.Name .. "' on action '" .. self._name .. "'", 2)
	end

	local BB = getBindingBuilder()
	local bindingBuilder = BB.new(keyCode, self, self._contextBuilder, self._trove)

	-- Parent the InputBinding to this action's InputAction
	bindingBuilder:getRawInstance().Parent = self._instance

	self._bindings[keyCode.Name] = bindingBuilder
	return bindingBuilder
end

function ActionBuilder.onPressed(
	self: ActionBuilderImpl,
	callback: (actionName: string) -> ()
): ActionBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	self:_wireEvents()
	table.insert(self._callbacks.pressed, callback)
	return self
end

function ActionBuilder.onReleased(
	self: ActionBuilderImpl,
	callback: (actionName: string) -> ()
): ActionBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	self:_wireEvents()
	table.insert(self._callbacks.released, callback)
	return self
end

function ActionBuilder.onStateChanged(
	self: ActionBuilderImpl,
	callback: (actionName: string, newState: boolean) -> ()
): ActionBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	self:_wireEvents()
	table.insert(self._callbacks.stateChanged, callback)
	return self
end

function ActionBuilder.getState(self: ActionBuilderImpl): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	return self._instance:GetState()
end

function ActionBuilder.context(self: ActionBuilderImpl): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	return self._contextBuilder
end

function ActionBuilder.destroy(self: ActionBuilderImpl)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._trove:Destroy()
end

function ActionBuilder.getRawInstance(self: ActionBuilderImpl): InputAction
	if self._destroyed then
		error("[EZInput] Cannot use destroyed action '" .. self._name .. "'", 2)
	end
	return self._instance
end

return ActionBuilder
