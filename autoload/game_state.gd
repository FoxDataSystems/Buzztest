extends Node

## Core game state machine (Lane 1 AC). Every other lane reads
## GameState.current_state / listens to state_changed rather than tracking
## its own notion of "what screen are we on".

enum State {
	MAIN_MENU,
	CHARACTER_CREATION,
	WORLD_LOADED,
	IN_GAME,
	GAME_OVER,
}

signal state_changed(previous: State, current: State)

var current_state: State = State.MAIN_MENU

## MAIN_MENU -> WORLD_LOADED covers "Load Game" (skips character creation).
## GAME_OVER -> WORLD_LOADED covers loading a save after a game-over screen.
const ALLOWED_TRANSITIONS := {
	State.MAIN_MENU: [State.CHARACTER_CREATION, State.WORLD_LOADED],
	State.CHARACTER_CREATION: [State.WORLD_LOADED],
	State.WORLD_LOADED: [State.IN_GAME],
	State.IN_GAME: [State.WORLD_LOADED, State.GAME_OVER, State.MAIN_MENU],
	State.GAME_OVER: [State.MAIN_MENU, State.WORLD_LOADED],
}

func can_transition_to(next_state: State) -> bool:
	return ALLOWED_TRANSITIONS.get(current_state, []).has(next_state)

func transition_to(next_state: State) -> bool:
	if not can_transition_to(next_state):
		push_warning("GameState: illegal transition from %s to %s" % [
			State.keys()[current_state], State.keys()[next_state],
		])
		return false
	var previous := current_state
	current_state = next_state
	state_changed.emit(previous, current_state)
	return true

## Test-only escape hatch; production callers must go through transition_to().
func _reset_for_tests() -> void:
	current_state = State.MAIN_MENU
