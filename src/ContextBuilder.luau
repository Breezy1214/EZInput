--!strict
local Trove = require(script.Parent.Packages.Trove)
local IASAdapter = require(script.Parent.IASAdapter)

-- Lazy require to break circular dependency (ContextBuilder <-> ActionBuilder)
local ActionBuilder
local function getActionBuilder()
	if not ActionBuilder then
		ActionBuilder = require(script.Parent.ActionBuilder)
	end
	return ActionBuilder
end

local ContextBuilder = {}
ContextBuilder.__index = ContextBuilder

export type ContextBuilderImpl = typeof(setmetatable(
	{} :: {
		_instance: InputContext,
		_trove: Trove.Trove,
		_name: string,
		_destroyed: boolean,
		_actions: { [string]: any },
		_registry: { [string]: any },
	},
	ContextBuilder
))

function ContextBuilder.new(name: string, registry: { [string]: any }): ContextBuilderImpl
	if registry[name] then
		error("[EZInput] Duplicate context name: '" .. name .. "'", 2)
	end

	local trove = Trove.new()
	local instance = trove:Add(IASAdapter.newContext(name))

	-- Parent to LocalPlayer.PlayerGui — standard IAS parent for client contexts
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	instance.Parent = localPlayer:WaitForChild("PlayerGui")

	-- Auto-enable on creation per project decision
	instance.Enabled = true

	local self = setmetatable({
		_instance = instance,
		_trove = trove,
		_name = name,
		_destroyed = false,
		_actions = {} :: { [string]: any },
		_registry = registry,
	}, ContextBuilder)

	registry[name] = self

	return self
end

function ContextBuilder.action(self: ContextBuilderImpl, name: string): any
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	if self._actions[name] then
		error("[EZInput] Duplicate action name: '" .. name .. "' in context '" .. self._name .. "'", 2)
	end

	local AB = getActionBuilder()
	local actionBuilder = AB.new(name, self, self._trove)

	-- Parent the InputAction to this context's InputContext
	actionBuilder:getRawInstance().Parent = self._instance

	self._actions[name] = actionBuilder
	return actionBuilder
end

--- Enables this context to process input. Contexts auto-enable on creation.
--- Higher-priority contexts fire before lower-priority ones.
function ContextBuilder.enable(self: ContextBuilderImpl): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Enabled = true
	return self
end

--- Disables this context. All actions and bindings remain configured but stop processing input.
function ContextBuilder.disable(self: ContextBuilderImpl): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Enabled = false
	return self
end

--- Sets context priority. Higher values fire first. Default is 0.
--- Use for layered input: UI menus (priority 10) override gameplay (priority 1).
function ContextBuilder.setPriority(self: ContextBuilderImpl, priority: number): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	self._instance.Priority = priority
	return self
end

--- When sink is true, this context blocks lower-priority contexts from receiving the same input.
--- When false (default), input passes through to all contexts regardless of priority.
function ContextBuilder.setSink(self: ContextBuilderImpl, sink: boolean): ContextBuilderImpl
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	-- selene: allow(incorrect_standard_library_use) -- InputActionSinkBehavior is a new IAS beta enum
	self._instance.Sink = if sink then Enum.InputActionSinkBehavior.Sink else Enum.InputActionSinkBehavior.PassThrough
	return self
end

function ContextBuilder.destroy(self: ContextBuilderImpl)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._registry[self._name] = nil
	self._trove:Destroy()
end

function ContextBuilder.getRawInstance(self: ContextBuilderImpl): InputContext
	if self._destroyed then
		error("[EZInput] Cannot use destroyed context '" .. self._name .. "'", 2)
	end
	return self._instance
end

return ContextBuilder
