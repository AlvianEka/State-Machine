class_name StateMachine
extends Node

signal state_changed(new_state: State)

@export var starting_state: State
@export var target: Node
@export var auto_start: bool = true
@export var find_recursive: bool = false

var active_state: State
var last_state: State
var is_running: bool
var is_transitioning: bool

var _states: Dictionary[StringName, State] = {}

var __state_trasition_queue: Array[StateTransitionData] = []


func _ready() -> void:
	if auto_start:
		state_machine_start()


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


func __process_single_state_transition(trans: StateTransitionData) -> void:
	var state: State = trans.state
	var data: Dictionary = trans.data

	if not is_instance_valid(state):
		push_warning("[%s] Invalid State" % name)
		return

	if active_state:
		await active_state._state_exit(state, data)
		active_state.is_active_state = false
		active_state.state_exited.emit()
		last_state = active_state

	active_state = state
	active_state.is_active_state = true
	state_changed.emit(active_state)

	await active_state._state_enter(last_state, data)
	active_state.state_entered.emit()


func state_machine_start(data: Dictionary = {}) -> void:
	if is_running:
		push_warning("[%s] StateMachine is already running" % name)
		return

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

		_states[state.name] = state

		if not starting_state:
			starting_state = state

	var success := change_state(starting_state)
	if success:
		is_running = true


func _process(delta: float) -> void:
	if not active_state:
		return
	active_state._state_process(delta)


func _physics_process(delta: float) -> void:
	if not active_state:
		return
	active_state._state_physics_process(delta)


func _input(event: InputEvent) -> void:
	if not active_state:
		return
	active_state._state_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if not active_state:
		return
	active_state._state_unhandled_input(event)


func change_state_by_name(state_name: StringName, data: Dictionary = {}) -> bool:
	var state := get_state(state_name)
	return change_state(state, data)


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


func get_state(state_name: StringName) -> State:
	var state: State = _states.get(state_name)
	if not state:
		push_warning("[%s] %s State not found" % [name, state_name])
	return state


class StateTransitionData:
	var state: State
	var data: Dictionary

	func _init(_state: State, _data: Dictionary) -> void:
		state = _state
		data = _data
