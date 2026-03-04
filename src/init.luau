--!strict
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	error("[EZInput] EZInput must be required on the client. IAS is client-only.", 2)
end

local Types = require(script.Types)
local ContextBuilder = require(script.ContextBuilder)

export type ContextBuilder = Types.ContextBuilder
export type ActionBuilder = Types.ActionBuilder
export type BindingBuilder = Types.BindingBuilder
export type OnPressed = Types.OnPressed
export type OnReleased = Types.OnReleased
export type OnStateChanged = Types.OnStateChanged

-- Shared context registry for duplicate name detection
local contextRegistry: { [string]: any } = {}

local EZInput = {}

function EZInput.context(name: string): Types.ContextBuilder
	return ContextBuilder.new(name, contextRegistry) :: any
end

return EZInput
