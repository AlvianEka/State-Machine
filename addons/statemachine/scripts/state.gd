@abstract
class_name State
extends Node
## Abstract base class for states in a finite state machine.
##
## Extend this class to create custom states that can be managed by a [StateMachine].

## Lifecycle status for this state as managed by a [StateMachine].
enum Status {
	## The state is not the current active state.
	## The state will not receive process, physics, or input callbacks.
	INACTIVE,
	## The state is currently running it's enter transition.
	ENTERING,
	## The state is the current active state.
	## The state may receive process/physics/input callbacks.
	ACTIVE,
	## The state is currently running it's exit transition.
	EXITING,
}

## Emitted after [method State._state_enter] completes.
signal state_entered
## Emitted after [method State._state_exit] completes.
signal state_exited
## Emitted when [member State.status] changes.
signal status_changed(status: Status)

## Current lifecycle [enum Status] of this state.
## This is updated by the owning [StateMachine].
var status := Status.INACTIVE:
	set(value):
		if value == status:
			return
		status = value
		status_changed.emit(status)

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
