--!strict
local IASAdapter = {}

function IASAdapter.newContext(name: string): InputContext
	local context = Instance.new("InputContext")
	context.Name = name
	context.Enabled = false
	return context
end

function IASAdapter.newAction(name: string, actionType: Enum.InputActionType): InputAction
	local action = Instance.new("InputAction")
	action.Name = name
	action.Type = actionType
	return action
end

function IASAdapter.newBinding(keyCode: Enum.KeyCode): InputBinding
	local binding = Instance.new("InputBinding")
	binding.KeyCode = keyCode
	return binding
end

return IASAdapter
