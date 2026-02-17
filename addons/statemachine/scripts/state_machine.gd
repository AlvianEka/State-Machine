class_name StateMachine
extends Node
## Finite state machine node that manages child [State] nodes.

## Emitted when the active state changes.
signal state_changed(new_state: State)

## The initial state to use when the state machine starts.
## If empty, the first discovered [State] child will be used.
@export var starting_state: State
## The Node that states should act upon.
## If empty, defaults to the parent of this state machine.
@export var target: Node
## If true, the state machine starts automatically on ready.
## If false, start it manually by calling [method state_machine_start].
@export var auto_start: bool = true
## If true, states will be searched recursively in all descendants, not just direct children.
@export var find_recursive: bool = false

## The currently active state (read-only).
var active_state: State
## The previously active state (read-only).
var last_state: State
## True while the state machine is transitioning (read-only).
var is_transitioning: bool

# Internal dictionary mapping state names to state instances.
var _state_registry: Dictionary[StringName, State] = {}
# Internal queue of pending state transitions.
var __state_trasition_queue: Array[StateTransitionData] = []


func _ready() -> void:
	__state_machine_init()

	if auto_start:
		change_state(starting_state)


func _process(delta: float) -> void:
	if not active_state:
		return

	if active_state.status != State.Status.ACTIVE:
		return

	active_state._state_process(delta)


func _physics_process(delta: float) -> void:
	if not active_state:
		return

	if active_state.status != State.Status.ACTIVE:
		return

	active_state._state_physics_process(delta)


func _input(event: InputEvent) -> void:
	if not active_state:
		return

	if active_state.status != State.Status.ACTIVE:
		return

	active_state._state_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if not active_state:
		return

	if active_state.status != State.Status.ACTIVE:
		return

	active_state._state_unhandled_input(event)


# discovering child states and register them
func __state_machine_init() -> void:
	if starting_state and starting_state.get_parent() != self:
		push_error(
			"[%s] Starting state '%s' is not a child of this StateMachine node" %
			[name, starting_state.name]
		)
		return

	if not target:
		target = get_parent()

	var descendant: Array = find_children("*", "", find_recursive, false)
	for child in descendant:
		if not child is State:
			continue

		var state := child as State
		state.state_machine = self
		state.target = target

		_state_registry[state.name] = state

		if not starting_state:
			starting_state = state


# State transitions can involve awaits (exit/enter), and we want them to run in order 
# so states always exit, transition, and enter cleanly without overlapping.
func __process_state_transition() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	while __state_trasition_queue:
		if not is_inside_tree():
			return

		var state_trans: StateTransitionData = __state_trasition_queue.pop_front()
		await __process_single_state_transition(state_trans)

	is_transitioning = false


# Internal method that performs a single state transition.
# Exits the current state, updates references, and enters the new state.
func __process_single_state_transition(trans: StateTransitionData) -> void:
	var state: State = trans.state
	var data: Dictionary = trans.data

	if not is_instance_valid(state):
		push_warning("[%s] Invalid State" % name)
		return

	if active_state:
		active_state.status = State.Status.EXITING
		await active_state._state_exit(state, data)
		active_state.state_exited.emit()
		active_state.status = State.Status.INACTIVE
		last_state = active_state

	active_state = state
	state_changed.emit(active_state)

	active_state.status = State.Status.ENTERING
	await active_state._state_enter(last_state, data)
	active_state.state_entered.emit()
	active_state.status = State.Status.ACTIVE


## Transition to the state using it's Name.[br]
## [b]Param data:[/b] Optional dictionary passed to the [State].
func change_state_by_name(state_name: StringName, data: Dictionary = {}) -> bool:
	var state := get_state(state_name)
	return change_state(state, data)


## Transition to the given [State].[br]
## [b]Param data:[/b] Optional dictionary passed to the [State].
func change_state(state: State, data: Dictionary = {}) -> bool:
	if not state:
		push_warning(
			"[%s] State can't be null, skipping state changes" % name
		)
		return false

	if active_state == state and __state_trasition_queue.is_empty():
		push_warning(
			"[%s] Already in state '%s', skipping state change" % [name, state.name]
		)
		return false

	if not __state_trasition_queue.is_empty() and __state_trasition_queue.back() == state:
		push_warning(
			"[%s] State '%s' already queued for transition, skipping duplicate" %
			[name, state.name]
		)
		return false

	var state_trans := StateTransitionData.new(state, data)
	__state_trasition_queue.append(state_trans)

	__process_state_transition.call_deferred()

	return true


## Returns the registered state with the given name, or null if not found.
func get_state(state_name: StringName) -> State:
	var state: State = _state_registry.get(state_name)
	if not state:
		push_warning("[%s] %s State not found" % [name, state_name])
	return state


class StateTransitionData:
	var state: State
	var data: Dictionary

	func _init(_state: State, _data: Dictionary) -> void:
		state = _state
		data = _data
