@abstract
class_name State
extends Node

signal state_entered
signal state_exited

var is_active_state: bool
var state_machine: StateMachine
var target: Node


func _state_enter(last_state: State, data: Dictionary) -> void:
	pass


func _state_exit(next_state: State, data: Dictionary) -> void:
	pass


func _state_process(delta: float) -> void:
	pass


func _state_physics_process(delta: float) -> void:
	pass


func _state_input(event: InputEvent) -> void:
	pass


func _state_unhandled_input(event: InputEvent) -> void:
	pass
