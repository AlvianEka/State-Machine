@abstract
class_name State
extends Node
## Abstract base class for states in a finite state machine.
##
## Extend this class to create custom states that can be managed by a [StateMachine].

## Emitted after [method State._state_enter] completes.
signal state_entered
## Emitted after [method State._state_exit] completes.
signal state_exited

## True while this State is the [member StateMachine.active_state].
var is_active_state: bool
## The StateMachine instance that owns this state.
## Assigned automatically when the state is registered.
var state_machine: StateMachine
## The Node that this state should act upon.
## Typically the same as the [member StateMachine.target],
## assigned automatically by [StateMachine].
var target: Node


## Called by [StateMachine] when this state becomes active, after the previous state exits.
func _state_enter(last_state: State, data: Dictionary) -> void:
	pass


## Called by [StateMachine] when this state is about to leave, before the next state enters.
func _state_exit(next_state: State, data: Dictionary) -> void:
	pass


## Calledby [StateMachine] every frame while this state is active.
func _state_process(delta: float) -> void:
	pass


## Called by [StateMachine] every physics frame while this state is active.
func _state_physics_process(delta: float) -> void:
	pass


## Called by [StateMachine] when an input event occurs while this state is active.
func _state_input(event: InputEvent) -> void:
	pass


## Called by [StateMachine] when an unhandled input event occurs while this state is active.
func _state_unhandled_input(event: InputEvent) -> void:
	pass
