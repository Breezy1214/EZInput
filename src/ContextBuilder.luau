--!strict
local Janitor = require(script.Parent.Parent.Janitor)
local IASAdapter = require(script.Parent.IASAdapter)

-- Lazy require to break circular dependency (ContextBuilder <-> ActionBuilder)
local ActionBuilder = require(script.Parent.ActionBuilder)

--- @class ContextBuilder
local ContextBuilder = {}
ContextBuilder.__index = ContextBuilder

export type ContextBuilderImpl = typeof(setmetatable(
	{} :: {
		_instance: InputContext,
		_janitor: typeof(Janitor.new()),
		_name: string,
		_destroyed: boolean,
		_actions: { [string]: any },
		_registry: { [string]: any },
	},
	ContextBuilder
))

--- Creates a new input context and registers it by name.
--- @param name string
--- @param registry table<string, any>
--- @return ContextBuilder
function ContextBuilder.new(name: string, registry: { [string]: any }): ContextBuilderImpl
	if registry[name] then
		error("[EZInput] Duplicate context name: '" .. name .. "'", 2)
	end

	local janitor = Janitor.new()
	local instance = janitor:Add(IASAdapter.newContext(name))

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	instance.Parent = localPlayer:WaitForChild("PlayerGui")
	instance.Enabled = true

	local self = setmetatable({
		_instance = instance,
		_janitor = janitor,
		_name = name,
		_destroyed = false,
		_actions = {} :: { [string]: any },
		_registry = registry,
	}, ContextBuilder)

	registry[name] = self

	return self
end

--- Creates and parents an action under this context.
--- @param name string
--- @return ActionBuilder
function ContextBuilder.action(self: ContextBuilderImpl, name: string): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	if self._actions[name] then
		error("[EZInput] Duplicate action name: '" .. name .. "' in context '" .. self._name .. "'", 2)
	end

	local actionBuilder = ActionBuilder.new(name, self, self._janitor)
	actionBuilder:getRawInstance().Parent = self._instance

	self._actions[name] = actionBuilder
	return actionBuilder
end

--- Enables this context so it can process input.
--- @return ContextBuilder
function ContextBuilder.enable(self: ContextBuilderImpl): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Enabled = true
	return self
end

--- Disables this context while preserving configured actions and bindings.
--- @return ContextBuilder
function ContextBuilder.disable(self: ContextBuilderImpl): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Enabled = false
	return self
end

--- Sets context priority. Higher values receive input first.
--- @param priority number
--- @return ContextBuilder
function ContextBuilder.setPriority(self: ContextBuilderImpl, priority: number): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Priority = priority
	return self
end

--- Sets whether this context blocks lower-priority contexts for matching input.
--- @param sink boolean
--- @return ContextBuilder
function ContextBuilder.setSink(self: ContextBuilderImpl, sink: boolean): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Sink = sink
	return self
end

--- Destroys this context and removes it from the context registry.
function ContextBuilder.destroy(self: ContextBuilderImpl)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._registry[self._name] = nil
	self._janitor:Destroy()
end

--- Returns the underlying InputContext instance.
--- @return InputContext
function ContextBuilder.getRawInstance(self: ContextBuilderImpl): InputContext
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	return self._instance
end

return ContextBuilder
