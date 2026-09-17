extends Node

## Placeholder entry point. Lane 8 (Pixel) replaces this with the real
## main-menu scene; GameState is the source of truth for what screen
## should be showing, not this script.

func _ready() -> void:
	print("GameState boot: ", GameState.State.keys()[GameState.current_state])
