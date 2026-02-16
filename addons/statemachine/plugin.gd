@tool
extends EditorPlugin


func _enable_plugin() -> void:
	var state_machine = preload("res://addons/statemachine/scripts/state_machine.gd")
	add_custom_type("StateMachine", "Node", state_machine, null)


func _disable_plugin() -> void:
	remove_custom_type("StateMachine")
