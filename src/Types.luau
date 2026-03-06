--!strict
export type OnPressed = (actionName: string) -> ()
export type OnReleased = (actionName: string) -> ()
export type OnStateChanged = (actionName: string, newState: boolean) -> ()
export type ContextBuilder = {
	action: (self: ContextBuilder, name: string) -> ActionBuilder,
	enable: (self: ContextBuilder) -> ContextBuilder,
	disable: (self: ContextBuilder) -> ContextBuilder,
	setPriority: (self: ContextBuilder, priority: number) -> ContextBuilder,
	setSink: (self: ContextBuilder, sink: boolean) -> ContextBuilder,
	destroy: (self: ContextBuilder) -> (),
	getRawInstance: (self: ContextBuilder) -> InputContext,
}

export type ActionBuilder = {
	bind: (self: ActionBuilder, keyCode: Enum.KeyCode) -> BindingBuilder,
	onPressed: (self: ActionBuilder, callback: OnPressed) -> ActionBuilder,
	onReleased: (self: ActionBuilder, callback: OnReleased) -> ActionBuilder,
	onStateChanged: (self: ActionBuilder, callback: OnStateChanged) -> ActionBuilder,
	getState: (self: ActionBuilder) -> any,
	context: (self: ActionBuilder) -> ContextBuilder,
	getRawInstance: (self: ActionBuilder) -> InputAction,
}

export type BindingBuilder = {
	withModifier: (self: BindingBuilder, modifier: Enum.KeyCode) -> BindingBuilder,
	withSecondaryModifier: (self: BindingBuilder, modifier: Enum.KeyCode) -> BindingBuilder,
	bind: (self: BindingBuilder, keyCode: Enum.KeyCode) -> BindingBuilder,
	action: (self: BindingBuilder) -> ActionBuilder,
	context: (self: BindingBuilder) -> ContextBuilder,
	getRawInstance: (self: BindingBuilder) -> InputBinding,
}

return {}
