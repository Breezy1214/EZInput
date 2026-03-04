--!strict
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	error("[EZInput] EZInput must be required on the client. IAS is client-only.", 2)
end

local Types = require(script.Types)

export type ContextBuilder = Types.ContextBuilder
export type ActionBuilder = Types.ActionBuilder
export type BindingBuilder = Types.BindingBuilder
export type OnPressed = Types.OnPressed
export type OnReleased = Types.OnReleased
export type OnStateChanged = Types.OnStateChanged

local EZInput = {}

-- Phase 2 will implement this
function EZInput.context(_name: string): Types.ContextBuilder
	error("[EZInput] Not yet implemented — Phase 2 provides the builder implementation.", 2)
end

return EZInput
