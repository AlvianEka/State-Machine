# State-Machine

This project is a small finite state machine addon for Godot. You add a **StateMachine** node, then put your **State** nodes as children (can be recursive too). The state machine will pick a starting state (or you set it), and it will call the active state every frame / physics / input, so your logic is not all mixed in one script.

When you change state, it do clean exit/enter: old state get `_state_exit(next_state, data)` and new state get `_state_enter(last_state, data)`, and you can pass a Dictionary data if you want. Transitions is queued, so if you call change many times it still go one by one, no overlap weird stuff.
